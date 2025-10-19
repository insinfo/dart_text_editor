// Arquivo: C:\MyDartProjects\canvas_text_editor\lib\layout\paragraph_layouter.dart
import 'package:dart_text_editor/core/offset.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/layout/page_constraints.dart';
import 'package:dart_text_editor/layout/paragraph_layout_result.dart';
import 'package:dart_text_editor/layout/layout_line.dart';
import 'package:dart_text_editor/render/measure_cache.dart';

class ParagraphLayouter {
  final MeasureCache measureCache;

  ParagraphLayouter(this.measureCache);

  ParagraphLayoutResult layout(
      ParagraphNode node, PageConstraints constraints) {
    final lines = <LayoutLine>[];
    var currentLineSpans = <LayoutSpan>[];
    var currentLineWidth = 0.0;
    var totalHeight = 0.0;
    var cursorInNode = 0;

    double lineHeightFor(List<LayoutSpan> spans) {
      if (spans.isEmpty) return 16.0 * node.attributes.lineSpacing;
      final maxFont = spans
          .map((s) => s.run.attributes.fontSize ?? 16.0)
          .reduce((a, b) => a > b ? a : b);
      return maxFont * node.attributes.lineSpacing * constraints.zoomLevel;
    }

    void breakLineNow() {
      if (currentLineSpans.isEmpty) return;
      final h = lineHeightFor(currentLineSpans);
      lines.add(LayoutLine(List.of(currentLineSpans), h, currentLineWidth));
      totalHeight += h;
      currentLineSpans.clear();
      currentLineWidth = 0.0;
    }

    void pushSpan(String text, TextRun run, int startInNode, double width) {
      if (text.isEmpty) return;
      currentLineSpans.add(LayoutSpan(
        run.copyWith(text: text),
        startInNode,
        startInNode + text.length,
      ));
      currentLineWidth += width;
    }

    void pushHiddenSpan(String text, TextRun run, int startInNode) {
      if (text.isEmpty) return;
      currentLineSpans.add(LayoutSpan.hidden(
        run.copyWith(text: text),
        startInNode,
        startInNode + text.length,
      ));
    }

    final tokenRegex = RegExp(r'(\s+|\S+)');

    for (final run in node.runs) {
      final text = run.text;
      if (text.isEmpty) {
        cursorInNode += run.text.length;
        continue;
      }

      final matches = tokenRegex.allMatches(text);
      var posInRun = 0;

      for (final match in matches) {
        final token = match.group(0)!;
        final tokenWidth = measureCache.measure(token, run.attributes).width;
        final isSpace = token.trim().isEmpty;
        final startOffsetInNode = cursorInNode + posInRun;

        
        // 1. Se o token não cabe na linha atual (e a linha não está vazia), quebra.
        // if (currentLineWidth > 0 &&
        //     currentLineWidth + tokenWidth > constraints.width &&
        //     !isSpace) {
        //   breakLineNow();
        // }
        // LÓGICA DE QUEBRA CORRIGIDA
        // 1. Se o token não cabe na linha atual (e a linha não está vazia), quebra.
        if (currentLineWidth > 0 &&
            currentLineWidth + tokenWidth > constraints.width) {
          breakLineNow();
        }

        // 2. Lida com palavras que são maiores que a própria linha
        if (tokenWidth > constraints.width && !isSpace) {
          var startInToken = 0;
          while (startInToken < token.length) {
            var endInToken = startInToken;
            var lastFitEnd = startInToken;
            var fragmentWidth = 0.0;
            // Encontra o maior fragmento que cabe na linha
            while (endInToken < token.length) {
              final nextChar = token.substring(endInToken, endInToken + 1);
              final nextCharWidth =
                  measureCache.measure(nextChar, run.attributes).width;
              if (currentLineWidth + fragmentWidth + nextCharWidth >
                  constraints.width) {
                break;
              }
              fragmentWidth += nextCharWidth;
              endInToken++;
              lastFitEnd = endInToken;
            }

            if (lastFitEnd == startInToken) {
              if (currentLineWidth > 0) breakLineNow();
              lastFitEnd = startInToken + 1; // Força pelo menos 1 char
            }

            final fragment = token.substring(startInToken, lastFitEnd);
            final fragWidth =
                measureCache.measure(fragment, run.attributes).width;
            pushSpan(
                fragment, run, startOffsetInNode + startInToken, fragWidth);
            startInToken = lastFitEnd;

            if (startInToken < token.length) {
              breakLineNow();
            }
          }
        } else {
          // 3. Adiciona o token à linha (nova ou atual)
          if (isSpace && currentLineWidth == 0) {
            pushHiddenSpan(token, run, startOffsetInNode);
          } else {
            pushSpan(token, run, startOffsetInNode, tokenWidth);
          }
        }
        posInRun += token.length;
      }
      cursorInNode += run.text.length;
    }

    if (currentLineSpans.isNotEmpty) {
      breakLineNow();
    }

    return ParagraphLayoutResult(lines, totalHeight);
  }

  Offset getCaretXY(
      ParagraphLayoutResult layoutResult, int lineIndex, int column) {
    if (layoutResult.lines.isEmpty) return Offset.zero;
    lineIndex = lineIndex.clamp(0, layoutResult.lines.length - 1);

    double y = 0.0;
    for (var i = 0; i < lineIndex; i++) {
      y += layoutResult.lines[i].height;
    }
    final line = layoutResult.lines[lineIndex];

    var rel = column;
    var x = 0.0;

    for (final span in line.spans) {
      final spanLen = span.endInNode - span.startInNode;

      if (rel <= 0) break;

      if (span.hidden) {
        rel -= spanLen;
        continue;
      }

      final run = span.run;
      if (rel <= spanLen) {
        final sub = run.text.substring(0, rel);
        x += measureCache.measure(sub, run.attributes).width;
        rel = 0;
        break;
      } else {
        x += measureCache.measure(run.text, run.attributes).width;
        rel -= spanLen;
      }
    }

    return Offset(x, y);
  }

  int getIndexFromXY(ParagraphLayoutResult layoutResult, double x, double y) {
    if (layoutResult.lines.isEmpty) return 0;

    var yOffset = 0.0;
    var lineIndex = -1;
    for (var i = 0; i < layoutResult.lines.length; i++) {
      final h = layoutResult.lines[i].height;
      if (y >= yOffset && y < yOffset + h) {
        lineIndex = i;
        break;
      }
      yOffset += h;
    }

    if (lineIndex == -1) {
      return layoutResult.lines.last.spans.last.endInNode;
    }

    final line = layoutResult.lines[lineIndex];
    if (line.spans.isEmpty) {
      return lineIndex > 0
          ? layoutResult.lines[lineIndex - 1].spans.last.endInNode
          : 0;
    }

    var absoluteOffset = line.spans.first.startInNode;
    var xCursor = 0.0;

    for (final span in line.spans) {
      if (span.hidden) {
        absoluteOffset += span.run.text.length;
        continue;
      }

      final run = span.run;
      for (var i = 0; i < run.text.length; i++) {
        final ch = run.text[i];
        final w = measureCache.measure(ch, run.attributes).width;
        if (x < xCursor + w / 2) {
          return absoluteOffset;
        }
        xCursor += w;
        absoluteOffset++;
      }
    }

    return line.spans.last.endInNode;
  }
}
