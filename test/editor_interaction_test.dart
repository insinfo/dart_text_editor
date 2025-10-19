import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/editor.dart';
import 'package:dart_text_editor/layout/paginator.dart';
import 'package:dart_text_editor/layout/page_constraints.dart';
import 'package:dart_text_editor/render/measure_cache.dart';
import 'package:test/test.dart';
import 'mocks/mock_text_measurer.dart';
import 'mocks/manual_dom_api_mocks.dart';

void main() {
  group('Editor Interactions', () {
    late MockCanvasElementApi mockCanvas;
    late MockDivElementApi mockOverlay;
    late MockWindowApi mockWindow;
    late MockDocumentApi mockDocument;
    late MockTextMeasurer mockTextMeasurer;
    late MeasureCache measureCache;
    late Paginator paginator;
    late DocumentModel document;

    setUp(() {
      mockCanvas = MockCanvasElementApi();
      mockOverlay = MockDivElementApi();
      mockWindow = MockWindowApi();
      mockDocument = MockDocumentApi();
      mockTextMeasurer = MockTextMeasurer();
      measureCache = MeasureCache(mockTextMeasurer);
      paginator = Paginator(measureCache);

      document = DocumentModel([
        ParagraphNode([TextRun(0, 'Hello world', const InlineAttributes())]),
        ParagraphNode([TextRun(0, 'Another line', const InlineAttributes())]),
      ]);

      paginator.paginate(document, PageConstraints.a4());
    });

    test('click in the middle of a span sets collapsed selection correctly',
        () async {
      final editor = Editor(
        mockCanvas,
        document,
        window: mockWindow,
        documentApi: mockDocument,
        paginator: paginator,
        overlay: mockOverlay,
        measureCache: measureCache,
      );

      final rect = mockCanvas.getBoundingClientRect();
      final localX = 50.0;
      final localY = 20.0;
      final clickX = (rect.left + localX).toInt();
      final clickY = (rect.top + localY).toInt();

      // CORREÇÃO: Usar o método trigger
      mockOverlay.triggerMouseDown(
          MockMouseEventApi(clientX: clickX, clientY: clickY));
      await Future.microtask(() {});

      final expectedPosition =
          editor.paginator.getPositionFromScreen(localX, localY);
      expect(editor.state.selection, Selection.collapsed(expectedPosition!));
    });

    test('typing a character inserts into the document when overlay is focused',
        () async {
      final editor = Editor(
        mockCanvas,
        document,
        window: mockWindow,
        documentApi: mockDocument,
        paginator: paginator,
        overlay: mockOverlay,
        measureCache: measureCache,
      );

      mockOverlay.focus();
      // CORREÇÃO: Usar o método trigger
      mockOverlay.triggerKeyDown(MockEventApi(key: 'a'));
      await Future.microtask(() {});

      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          'aHello world');
    });

    test('pressing Enter splits paragraph and moves caret', () async {
      final editor = Editor(
        mockCanvas,
        document,
        window: mockWindow,
        documentApi: mockDocument,
        paginator: paginator,
        overlay: mockOverlay,
        measureCache: measureCache,
      );

      editor.state = editor.state
          .copyWith(selection: Selection.collapsed(const Position(0, 5)));
      mockOverlay.focus();
      // CORREÇÃO: Usar o método trigger
      mockOverlay.triggerKeyDown(MockEventApi(key: 'Enter'));
      await Future.microtask(() {});

      expect(editor.state.document.nodes.length, 3);
      expect(editor.state.selection.start.node, 1);
      expect(editor.state.selection.start.offset, 0);
    });
  });
}
