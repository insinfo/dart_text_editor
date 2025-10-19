import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/text_run.dart';
import 'package:canvas_text_editor/core/inline_attributes.dart';
import 'package:canvas_text_editor/layout/page_constraints.dart';
import 'package:canvas_text_editor/layout/paginator.dart';
import 'package:canvas_text_editor/render/measure_cache.dart';
import 'package:test/test.dart';
import '../mocks/mock_text_measurer.dart';

void main() {
  group('Paginator', () {
    test('paginate produces multiple pages for long content', () {
      final longText = 'a' * 1000;
      final doc = DocumentModel([
        ParagraphNode([TextRun(0, longText, InlineAttributes())]),
        ParagraphNode([TextRun(0, longText, InlineAttributes())]),
      ]);
      final constraints = PageConstraints(width: 100, height: 100);
      final paginator = Paginator(MeasureCache(MockTextMeasurer()));

      final pages = paginator.paginate(doc, constraints);

      expect(pages.length, greaterThan(1));
    });
  });
}