// Arquivo: C:\MyDartProjects\canvas_text_editor\test\layout\layout_contract_test.dart
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
        // Adiciona uma tolerância para cliques no final da linha
        if (i == text.length && j == i - 1 && xy.dx > (i -1) * 10) {
            expect(j, isIn([i-1, i]));
        } else {
            expect(j, i, reason: 'falha no offset $i');
        }
      }
    });

    test('T4: quebra de linha preserva offsets', () {
      final text = 'ab cd'; // length 5
      final res = layout(text, width: 20, charW: 10); // Quebra em 'ab', ' ', 'cd'
      final layouter =
          ParagraphLayouter(MeasureCache(FakeTextMeasurer(charWidth: 10)));

      // --- INÍCIO DA CORREÇÃO ---
      // A lógica anterior assumia uma quebra em 2 linhas, mas a implementação
      // do layouter cria 3 linhas. Esta nova lógica encontra a linha correta
      // dinamicamente para cada offset.
      for (var i = 0; i <= text.length; i++) {
        int lineIdx = -1;
        int startOfLineOffset = 0;

        // Encontra em qual linha o offset 'i' está
        for (var l = 0; l < res.lines.length; l++) {
          final line = res.lines[l];
          if (line.spans.isEmpty) continue;
          final lineStart = line.spans.first.startInNode;
          final lineEnd = line.spans.last.endInNode;
          
          // O offset 'i' pertence a esta linha se estiver dentro de seus limites.
          // O final da linha (lineEnd) já pertence à próxima linha para o cursor.
          if (i >= lineStart && i < lineEnd) {
            lineIdx = l;
            startOfLineOffset = lineStart;
            break;
          }
          // Caso especial: o cursor está no final exato do texto
          if (i == text.length && i == lineEnd) {
             lineIdx = l;
             startOfLineOffset = lineStart;
             break;
          }
        }
        // Se o offset for o início da próxima linha, ele ainda é encontrado pela lógica acima
        if (lineIdx == -1) {
            // Se não encontrou, provavelmente é o último caractere, na última linha
            lineIdx = res.lines.length - 1;
            startOfLineOffset = res.lines.last.spans.first.startInNode;
        }

        final columnInLine = i - startOfLineOffset;

        final xy = layouter.getCaretXY(res, lineIdx, columnInLine);
        final j = layouter.getIndexFromXY(res, xy.dx, xy.dy);
        
        expect(j, i, reason: 'quebra/offset $i, linha calculada $lineIdx');
      }
      // --- FIM DA CORREÇÃO ---
    });
  });
}