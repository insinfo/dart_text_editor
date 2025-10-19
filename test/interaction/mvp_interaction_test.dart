// Arquivo: C:\MyDartProjects\canvas_text_editor\test\interaction\mvp_interaction_test.dart
import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/editor.dart';

import 'package:dart_text_editor/layout/paginator.dart';
import 'package:dart_text_editor/render/measure_cache.dart';
import 'package:test/test.dart';
import '../mocks/mock_text_measurer.dart';
import '../mocks/manual_dom_api_mocks.dart';

void main() {
  group('MVP interaction tests', () {
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
    });

    test('cursor placement near edges and with multiple spaces', () async {
      document = DocumentModel([
        ParagraphNode([TextRun(0, 'Hello   world', const InlineAttributes())]),
      ]);

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
      final leftClickX = (rect.left + 60).toInt(); // Margem + 1 char
      final clickY = (rect.top + 60).toInt(); // Dentro da margem da página

      // CORREÇÃO: Usar o método trigger
      mockOverlay.triggerMouseDown(
          MockMouseEventApi(clientX: leftClickX, clientY: clickY));
      await Future.microtask(() {});
      final leftPos = editor.state.selection.start;

      final rightClickX = (rect.left + 300).toInt();
      // CORREÇÃO: Usar o método trigger
      mockOverlay.triggerMouseDown(
          MockMouseEventApi(clientX: rightClickX, clientY: clickY));
      await Future.microtask(() {});
      final rightPos = editor.state.selection.start;

      expect(leftPos.node, equals(0));
      expect(rightPos.node, equals(0));
      expect(leftPos.offset, lessThanOrEqualTo(rightPos.offset));
    });

    test('pressing Enter splits paragraph at caret', () async {
      document = DocumentModel([
        ParagraphNode([TextRun(0, 'ABCDE', const InlineAttributes())]),
      ]);

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
          .copyWith(selection: Selection.collapsed(const Position(0, 2)));
      // CORREÇÃO: Usar o método trigger
      mockOverlay.triggerKeyDown(MockEventApi(key: 'Enter'));
      await Future.microtask(() {});

      expect(editor.state.document.nodes.length, 2);
      expect(editor.state.selection.start.node, 1);
      expect(editor.state.selection.start.offset, 0);
    });

    test('mouse drag selects text across offsets', () async {
      document = DocumentModel([
        ParagraphNode([TextRun(0, 'Hello world', const InlineAttributes())]),
      ]);

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
      // CORREÇÃO: Coordenadas ajustadas para estarem dentro dos limites do bloco de texto
      // A margem padrão A4 é ~57pt. Os cliques devem estar além disso.
      final startX = (rect.left + 65).toInt(); // offset ~1
      final startY = (rect.top + 70).toInt();
      final endX = (rect.left + 120).toInt(); // offset ~8
      final endY = startY;

      // CORREÇÃO: Usar os métodos trigger
      mockOverlay.triggerMouseDown(
          MockMouseEventApi(clientX: startX, clientY: startY));
      await Future.microtask(() {});
      mockOverlay
          .triggerMouseMove(MockMouseEventApi(clientX: endX, clientY: endY));
      await Future.microtask(() {});
      mockOverlay
          .triggerMouseUp(MockMouseEventApi(clientX: endX, clientY: endY));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, false); // Agora deve passar
      expect(editor.state.selection.start.node, 0);
      expect(editor.state.selection.end.offset,
          greaterThan(editor.state.selection.start.offset));
    });
  });
}