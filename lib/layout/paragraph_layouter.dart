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

        final startOffsetInNode = cursorInNode + posInRun;

        if (currentLineWidth > 0 &&
            currentLineWidth + tokenWidth > constraints.width) {
          breakLineNow();
        }

        if (tokenWidth > constraints.width && token.trim().isNotEmpty) {
          var startInToken = 0;
          while (startInToken < token.length) {
            var endInToken = startInToken;
            var lastFitEnd = startInToken;
            var fragmentWidth = 0.0;
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
              lastFitEnd = startInToken + 1;
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
          pushSpan(token, run, startOffsetInNode, tokenWidth);
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
    // Log da entrada da função
    print('[getIndexFromXY] Input: x=$x, y=$y');

    if (layoutResult.lines.isEmpty) {
      print('[getIndexFromXY] No lines in layoutResult, returning 0');
      return 0;
    }

    // ===== DEBUG DETALHADO DA VERIFICAÇÃO VERTICAL =====
    print(
        '[getIndexFromXY] --- Checking ${layoutResult.lines.length} Lines Vertically ---');
    var cumulativeY = 0.0; // Acumula a posição Y superior de cada linha
    bool lineFound = false;
    int targetLineIndex = -1;

    for (var i = 0; i < layoutResult.lines.length; i++) {
      final line = layoutResult.lines[i];
      final lineTop = cumulativeY;
      final lineHeight = line.height; // Use a altura calculada da linha
      final lineBottom = lineTop + lineHeight;
      final lineTextPreview = line.spans
          .map((s) => s.run.text)
          .join(); // Texto completo da linha para clareza

      // A verificação crucial: o Y de entrada está DENTRO dos limites verticais desta linha?
      bool yIsInLineBounds = (y >= lineTop && y < lineBottom);

      print(
          '[getIndexFromXY]   Line $i: yRange=[$lineTop..$lineBottom), height=$lineHeight | InputY=$y | InBounds=$yIsInLineBounds | Text="${lineTextPreview.substring(0, lineTextPreview.length.clamp(0, 40))}..."');

      if (yIsInLineBounds) {
        print('[getIndexFromXY]   ✓ Found Target Line: $i');
        targetLineIndex = i;
        lineFound = true;
        break; // Encontrou a linha correta verticalmente, pode parar de procurar
      }

      cumulativeY = lineBottom; // Prepara o topo da próxima linha
    }
    print('[getIndexFromXY] --- End Vertical Check ---');
    // ===== FIM DO DEBUG VERTICAL =====

    // Se NENHUMA linha foi encontrada verticalmente (clique abaixo de todo o conteúdo)
    if (!lineFound) {
      print(
          '[getIndexFromXY] InputY=$y is below all line ranges (last bottom was $cumulativeY).');
      // Retorna o final do último caractere da última linha, se houver
      if (layoutResult.lines.isNotEmpty &&
          layoutResult.lines.last.spans.isNotEmpty) {
        final lastOffset = layoutResult.lines.last.spans.last.endInNode;
        print('[getIndexFromXY]   -> Returning end of last span: $lastOffset');
        return lastOffset;
      } else {
        print(
            '[getIndexFromXY]   -> Layout has no lines or last line is empty, returning 0');
        return 0; // Documento vazio ou linha vazia
      }
    }

    // Se encontrou a linha (targetLineIndex é válido), prossiga com a busca horizontal NESSA linha
    final targetLine = layoutResult.lines[targetLineIndex];
    print(
        '[getIndexFromXY] --- Checking Spans Horizontally on Line $targetLineIndex ---');

    // Caso de linha vazia (sem spans)
    if (targetLine.spans.isEmpty) {
      print(
          '[getIndexFromXY]   Target line $targetLineIndex is empty. Returning offset 0 for this line.');
      // O offset absoluto seria o offset inicial do primeiro span da *próxima* linha,
      // ou o final do último span da linha *anterior*. Para simplificar, retornamos 0 *dentro* da linha vazia.
      // A lógica de `Position` e `offset` precisa ser consistente. Se uma linha vazia tem length 0,
      // o único offset válido nela é 0. O offset absoluto dependeria do conteúdo anterior.
      // Vamos retornar o offset inicial que *teria* sido o desta linha vazia.
      int startingOffsetForEmptyLine = 0;
      if (targetLineIndex > 0 &&
          layoutResult.lines[targetLineIndex - 1].spans.isNotEmpty) {
        startingOffsetForEmptyLine =
            layoutResult.lines[targetLineIndex - 1].spans.last.endInNode;
      }
      print(
          '[getIndexFromXY]   -> Returning start offset for empty line: $startingOffsetForEmptyLine');
      return startingOffsetForEmptyLine; // Retorna o offset onde a linha vazia começa
    }

    var absoluteOffset =
        targetLine.spans.first.startInNode; // Offset inicial da linha
    var xCursor = 0.0; // Posição X relativa ao início da linha

    for (final span in targetLine.spans) {
      if (span.hidden) {
        // Pula spans escondidos, mas atualiza o offset absoluto
        absoluteOffset += (span.endInNode - span.startInNode);
        continue;
      }

      final run = span.run;
      final metrics = measureCache.measure(run.text, run.attributes);
      final runWidth = metrics.width;
      final spanTextPreview =
          run.text.substring(0, run.text.length.clamp(0, 10));

      print(
          '[getIndexFromXY]   Span: xRange=[$xCursor..${xCursor + runWidth}), InputX=$x | StartOffset=${span.startInNode} | Text="$spanTextPreview..."');

      // Verifica se X está DENTRO deste span
      if (x >= xCursor && x < xCursor + runWidth) {
        // Estima o caractere dentro do span
        // Evita divisão por zero
        final charWidth =
            run.text.isNotEmpty ? runWidth / run.text.length : 1.0;
        // Calcula quantos caracteres "caberiam" até a posição X dentro deste span
        final charsIntoSpan =
            charWidth > 0 ? ((x - xCursor) / charWidth).round() : 0;
        // Garante que não exceda o tamanho do span
        final clampedChars = charsIntoSpan.clamp(0, run.text.length);

        absoluteOffset =
            span.startInNode + clampedChars; // Calcula o offset absoluto final

        print(
            '[getIndexFromXY]   ✓ Found Target Span! CharsInto=$clampedChars -> Absolute Offset=$absoluteOffset');
        print('[getIndexFromXY] --- End Horizontal Check ---');
        return absoluteOffset;
      }
      // Se o X é menor que o início do span atual, significa que o clique foi mais próximo
      // do final do span ANTERIOR ou do início DESTE span. Retornar o início deste span é o comportamento mais comum.
      else if (x < xCursor) {
        absoluteOffset = span.startInNode;
        print(
            '[getIndexFromXY]   InputX is before this span. Returning start of this span: $absoluteOffset');
        print('[getIndexFromXY] --- End Horizontal Check ---');
        return absoluteOffset;
      }

      // Move o cursor X para o final deste span para verificar o próximo
      xCursor += runWidth;
      // Atualiza o offset absoluto para o início do *próximo* span (ou final da linha)
      absoluteOffset = span.endInNode;
    } // Fim do loop de spans

    // Se o loop terminou, significa que X estava além do final de todos os spans na linha
    // O valor de 'absoluteOffset' já estará no final do último span
    print(
        '[getIndexFromXY]   InputX=$x is beyond all spans (last xCursor was $xCursor). Returning end of line offset: $absoluteOffset');
    print('[getIndexFromXY] --- End Horizontal Check ---');
    return absoluteOffset;
  }
}
