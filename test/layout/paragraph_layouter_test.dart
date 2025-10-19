import 'package:dart_text_editor/layout/paragraph_layouter.dart';
import 'package:dart_text_editor/render/measure_cache.dart';
import '../mocks/mock_text_measurer.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/layout/page_constraints.dart';
import 'package:test/test.dart';

void main() {
  group('ParagraphLayouter', () {
    late ParagraphLayouter layouter;
    late MeasureCache measureCache;

    setUp(() {
      measureCache = MeasureCache(MockTextMeasurer());
      layouter = ParagraphLayouter(measureCache);
    });

    test('wraps multiple words into multiple lines', () {
      final text = 'word1 word2 word3 word4';
      final node =
          ParagraphNode([TextRun(0, text, /*attributes*/ InlineAttributes())]);
      final constraints = PageConstraints(width: 100, height: 100);

      final result = layouter.layout(node, constraints);

      expect(result.lines.length, greaterThan(1));
    });

    test('preserves multiple spaces between words', () {
      final text = 'hello   world';
      final node = ParagraphNode([TextRun(0, text, InlineAttributes())]);
      final constraints = PageConstraints(width: 200, height: 100);

      final result = layouter.layout(node, constraints);

      // Ensure spans include the trimmed words; spaces measurement contributes to width
      expect(result.lines.isNotEmpty, true);
      // Check total characters accounted
      final totalChars = result.lines
          .map((l) =>
              l.spans.map((s) => s.run.text.length).fold(0, (a, b) => a + b))
          .fold(0, (a, b) => a + b);
      expect(totalChars, equals(text.length));
    });

    test('splits very long word into fragments that fit the line', () {
      final longWord = 'a' * 50;
      final node = ParagraphNode([TextRun(0, longWord, InlineAttributes())]);
      final constraints = PageConstraints(width: 100, height: 500);

      final result = layouter.layout(node, constraints);

      expect(result.lines.length, greaterThan(1));
    });
  });
}
