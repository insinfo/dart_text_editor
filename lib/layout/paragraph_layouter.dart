import 'package:canvas_text_editor/core/offset.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/text_run.dart';
import 'package:canvas_text_editor/layout/page_constraints.dart';
import 'package:canvas_text_editor/layout/paragraph_layout_result.dart';
import 'package:canvas_text_editor/layout/layout_line.dart';
import 'package:canvas_text_editor/render/measure_cache.dart';

/// Layouter com política correta de quebra:
/// - Quebra em whitespace **consome 1 espaço** para fechar a linha (não duplica).
/// - Espaços à esquerda da linha viram spans `hidden` (width=0), mas contam no offset.
/// - Múltiplos espaços são preservados (1:1 com o texto).
/// - Palavras muito longas são quebradas em fragmentos que caibam.
/// - getCaretXY / getIndexFromXY fazem mapeamento fiel texto⇄tela.
class ParagraphLayouter {
  final MeasureCache measureCache;

  ParagraphLayouter(this.measureCache);

  ParagraphLayoutResult layout(ParagraphNode node, PageConstraints constraints) {
    final lines = <LayoutLine>[];
    var currentLineSpans = <LayoutSpan>[];
    var currentLineWidth = 0.0;
    var totalHeight = 0.0;

    // Offset absoluto dentro do ParagraphNode (sempre 1:1 com node.text)
    var cursorInNode = 0;

    double lineHeightFor(List<LayoutSpan> spans) {
      if (spans.isEmpty) return 16.0 * node.attributes.lineSpacing;
      final maxFont = spans
          .map((s) => s.run.attributes.fontSize ?? 16.0)
          .reduce((a, b) => a > b ? a : b);
      return maxFont * node.attributes.lineSpacing * constraints.zoomLevel;
    }

    void breakLineNow() {
      final h = lineHeightFor(currentLineSpans);
      lines.add(LayoutLine(List.of(currentLineSpans), h, currentLineWidth));
      totalHeight += h;
      currentLineSpans.clear();
      currentLineWidth = 0.0;
    }

    // Adiciona span normal (visível)
    void pushSpan(String text, TextRun run, int startInNode) {
      if (text.isEmpty) return;
      final w = measureCache.measure(text, run.attributes).width;
      currentLineSpans.add(LayoutSpan(
        run.copyWith(text: text),
        startInNode,
        startInNode + text.length,
      ));
      currentLineWidth += w;
    }

    // Adiciona span oculto (conta no offset, não altera largura/x visual)
    void pushHiddenSpan(int count, TextRun run, int startInNode) {
      if (count <= 0) return;
      currentLineSpans.add(LayoutSpan.hidden(
        run.copyWith(text: ' ' * count),
        startInNode,
        startInNode + count,
      ));
      // width 0; NÃO mexe em currentLineWidth
    }

    // Separa texto do run em tokens preservando espaços: (\s+|\S+)
    final tokenRegex = RegExp(r'(\s+|\S+)');

    for (final run in node.runs) {
      final text = run.text;
      if (text.isEmpty) continue;

      final matches = tokenRegex.allMatches(text).toList();
      var posInRun = 0; // posição relativa dentro do run atual (0..text.length)

      int globalOffset(int local) => cursorInNode + local;

      for (final m in matches) {
        final token = m.group(0)!;
        final isSpace = token.trim().isEmpty;

        // ---------------- Espaços ----------------
        if (isSpace) {
          if (currentLineWidth > 0) {
            // Always add the space to the current line when there's content
            pushSpan(token, run, globalOffset(posInRun));
            posInRun += token.length;
            
            // If we're near the right edge, break to next line
            if (currentLineWidth + measureCache.measure(" ", run.attributes).width >= constraints.width) {
              breakLineNow();
            }
          } else {
            // At start of line, treat as a hidden space
            pushHiddenSpan(token.length, run, globalOffset(posInRun));
            posInRun += token.length;
          }
          continue;
        }

        // ---------------- Palavra ----------------
        final tokenWidth = measureCache.measure(token, run.attributes).width;

        // Se a palavra não cabe na linha atual e já tem conteúdo, quebra a linha
        if (currentLineWidth > 0.0 && currentLineWidth + tokenWidth > constraints.width) {
          breakLineNow();
        }

        // Se ainda assim a palavra não couber (muito grande), fragmenta
        if (tokenWidth > constraints.width) {
          var start = 0;
          while (start < token.length) {
            var end = start + 1;
            var lastValidEnd = end;

            // Tenta estender até o máximo que couber na linha
            while (end <= token.length) {
              final fragment = token.substring(start, end);
              final fragmentWidth = measureCache.measure(fragment, run.attributes).width;
              
              if (currentLineWidth + fragmentWidth <= constraints.width) {
                lastValidEnd = end;
                end++;
              } else {
                break;
              }
            }

            // Se não conseguiu estender (nem 1 char cabe), força quebra de linha
            if (lastValidEnd == start && currentLineWidth > 0) {
              breakLineNow();
              continue;
            }

            // Adiciona o maior fragmento que coube
            final frag = token.substring(start, lastValidEnd);
            pushSpan(frag, run, globalOffset(posInRun + start));
            
            // Se ainda tem mais caracteres, quebra a linha
            start = lastValidEnd;
            if (start < token.length) {
              breakLineNow();
            }
          }
        } else {
          // Palavra cabe inteira na linha atual
          pushSpan(token, run, globalOffset(posInRun));
        }

        posInRun += token.length;
      }

      // Avança o cursor global pelo tamanho desse run
      cursorInNode += text.length;
    }

    if (currentLineSpans.isNotEmpty) {
      breakLineNow();
    }

    return ParagraphLayoutResult(lines, totalHeight);
  }

  /// Retorna (x,y) para linha/coluna **relativa à linha**.
  /// Spans `hidden` apenas consomem colunas; não afetam `x`.
  Offset getCaretXY(ParagraphLayoutResult layoutResult, int lineIndex, int column) {
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

  /// Mapeia (x,y) → offset no nó.
  /// `hidden` soma apenas offset; visível usa largura cumulativa por caractere.
  int getIndexFromXY(ParagraphLayoutResult layoutResult, double x, double y) {
    if (layoutResult.lines.isEmpty) return 0;

    // Seleciona a linha pelo Y
    var yOffset = 0.0;
    var lineIndex = 0;
    for (var i = 0; i < layoutResult.lines.length; i++) {
      final h = layoutResult.lines[i].height;
      if (y >= yOffset && y < yOffset + h) {
        lineIndex = i;
        break;
      }
      yOffset += h;
    }
    final line = layoutResult.lines[lineIndex];
    if (line.spans.isEmpty) return 0;

    var absoluteOffset = line.spans.first.startInNode;
    var xCursor = 0.0;

    for (final span in line.spans) {
      final spanLen = span.endInNode - span.startInNode;

      if (span.hidden) {
        absoluteOffset += spanLen;
        continue;
      }

      final run = span.run;
      for (var i = 0; i < run.text.length; i++) {
        final ch = run.text[i];
        final w = measureCache.measure(ch, run.attributes).width;
        if (x < xCursor + w / 2) {
          return absoluteOffset + i;
        }
        xCursor += w;
      }
      absoluteOffset += spanLen;
    }

    // Passou do fim: retorna fim da linha
    return line.spans.last.endInNode;
  }
}
