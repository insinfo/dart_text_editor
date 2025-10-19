import 'package:test/test.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/layout/paragraph_layouter.dart';
import 'package:dart_text_editor/layout/page_constraints.dart';
import 'package:dart_text_editor/render/measure_cache.dart';
import 'package:dart_text_editor/render/text_measurer_interface.dart';
import 'package:dart_text_editor/render/metrics.dart';
import 'package:dart_text_editor/layout/paragraph_layout_result.dart';

class FakeTextMeasurer implements TextMeasurerInterface {
  final double charWidth;
  FakeTextMeasurer({this.charWidth = 10});
  @override
  Metrics measure(String text, InlineAttributes attrs) {
    return TextMetrics(width: text.length * charWidth, height: 16.0);
  }
}

ParagraphLayoutResult layout(String text,
    {double width = 100, double charW = 10}) {
  final node = ParagraphNode([TextRun(0, text, InlineAttributes())]);
  final layouter =
      ParagraphLayouter(MeasureCache(FakeTextMeasurer(charWidth: charW)));
  final constraints = PageConstraints(width: width, height: 1000);
  return layouter.layout(node, constraints);
}

double baselineY(int line, {double lineHeight = 16.0}) => line * lineHeight;

void main() {
  group('Layout/Medidas - contrato texto ⇄ layout', () {
    test('T1: layout preserva espaços como parte das spans', () {
      final node = ParagraphNode([TextRun(0, 'a b', InlineAttributes())]);
      final layouter =
          ParagraphLayouter(MeasureCache(FakeTextMeasurer(charWidth: 10)));
      final constraints = PageConstraints(width: 100, height: 1000);
      final res = layouter.layout(node, constraints);
      final totalLen = res.lines
          .expand((l) => l.spans)
          .fold<int>(0, (s, sp) => s + (sp.endInNode - sp.startInNode));
      expect(totalLen, equals(3));
      final contemEspaco = res.lines.expand((l) => l.spans).any((sp) =>
          node.text.substring(sp.startInNode, sp.endInNode).contains(' '));
      expect(contemEspaco, isTrue);
    });

    test('T2: getCaretXY respeita espaço (fonte mono)', () {
      final res = layout('a b', width: 100, charW: 10);
      final layouter =
          ParagraphLayouter(MeasureCache(FakeTextMeasurer(charWidth: 10)));
      for (var i = 0; i <= 3; i++) {
        final xy = layouter.getCaretXY(res, 0, i);
        expect(xy.dx, equals(i * 10));
      }
    });

    test('T3: round-trip getCaretXY -> getIndexFromXY', () {
      final text = 'ab  cd e';
      final res = layout(text, width: 100, charW: 10);
      final layouter =
          ParagraphLayouter(MeasureCache(FakeTextMeasurer(charWidth: 10)));
      for (var i = 0; i <= text.length; i++) {
        final xy = layouter.getCaretXY(res, 0, i);
        final j = layouter.getIndexFromXY(res, xy.dx, xy.dy);
        expect(j, i, reason: 'falha no offset $i');
      }
    });

    test('T4: quebra de linha preserva offsets', () {
      final text = 'ab cd';
      final res = layout(text, width: 20, charW: 10); // quebra após ab
      final layouter =
          ParagraphLayouter(MeasureCache(FakeTextMeasurer(charWidth: 10)));
      // Debug: print spans and offsets for each line
      for (int l = 0; l < res.lines.length; l++) {
        final line = res.lines[l];
        print('Line $l:');
        for (final span in line.spans) {
          print(
              '  span [${span.startInNode}, ${span.endInNode}): "${span.run.text}"');
        }
      }

      // --- INÍCIO DA CORREÇÃO ---
      // Torna o teste robusto ao não usar um número "mágico" para a quebra.
      final endOfLine0Offset = res.lines[0].spans.last.endInNode;

      for (var i = 0; i <= text.length; i++) {
        // A posição do cursor no final da linha (offset 2) pertence à linha 0.
        // Portanto, usamos `<=` para a comparação.
        final lineIdx = i <= endOfLine0Offset ? 0 : 1;

        final startOfLineOffset = (lineIdx == 0)
            ? res.lines[0].spans.first.startInNode
            : res.lines[1].spans.first.startInNode;

        final columnInLine = i - startOfLineOffset;

        final xy = layouter.getCaretXY(res, lineIdx, columnInLine);
        final j = layouter.getIndexFromXY(res, xy.dx, xy.dy);

        expect(j, i, reason: 'quebra/offset $i');
      }
      // --- FIM DA CORREÇÃO ---
    });
    //fim
  });
}
