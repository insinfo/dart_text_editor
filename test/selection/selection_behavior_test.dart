// Arquivo: C:\MyDartProjects\canvas_text_editor\test\selection\selection_behavior_test.dart
import 'package:test/test.dart';
import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/editor.dart';
import '../mocks/manual_dom_api_mocks.dart';
import '../mocks/mock_text_measurer.dart';
import 'package:dart_text_editor/render/measure_cache.dart';
import 'dart:async';

void main() {
  group('Selection Behavior Tests', () {
    late DocumentModel document;
    late Editor editor;
    late MockCanvasElementApi canvas;
    late MockDivElementApi overlay;

    setUp(() {
      document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'First paragraph with ', const InlineAttributes()),
          TextRun(23, 'bold', const InlineAttributes(bold: true)),
          TextRun(27, ' text.', const InlineAttributes()),
        ]),
        ParagraphNode([
          TextRun(0, 'Second paragraph with ', const InlineAttributes()),
          TextRun(22, 'italic', const InlineAttributes(italic: true)),
          TextRun(28, ' content.', const InlineAttributes()),
        ])
      ]);

      canvas = MockCanvasElementApi();
      overlay = MockDivElementApi();
      editor = Editor(
        canvas,
        document,
        measureCache: MeasureCache(MockTextMeasurer()),
        overlay: overlay,
      );
    });

    test('Click in middle of span creates collapsed selection', () async {
      // CORREÇÃO: Coordenadas ajustadas para considerar a margem da página (~57pt)
      // clientX = margem + (offset_desejado * largura_char_mock)
      // clientX = 57 + (10 * 8) = 137
      overlay.triggerMouseDown(MockMouseEventApi(clientX: 137, clientY: 70));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, true);
      // O Paginator mockado retornará uma posição baseada no X.
      expect(editor.state.selection.start.offset, 10);
    });

    test('Drag selection across lines selects correct text', () async {
      // CORREÇÃO: Coordenadas ajustadas para estarem dentro dos limites dos blocos de texto
      overlay.triggerMouseDown(MockMouseEventApi(clientX: 137, clientY: 70)); // Nó 0, offset 10
      await Future.microtask(() {});
      // Y maior para clicar na segunda linha/parágrafo
      overlay.triggerMouseMove(MockMouseEventApi(clientX: 153, clientY: 100)); // Nó 1, offset 12
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, false); // Agora deve passar
      expect(editor.state.selection.start.node, 0);
      expect(editor.state.selection.end.node, 1);
    });

    test('SHIFT + arrows extends selection from anchor', () async {
      editor.state = editor.state
          .copyWith(selection: Selection.collapsed(const Position(0, 10)));

      // CORREÇÃO: Usar o método trigger
      overlay.triggerKeyDown(MockEventApi(key: 'ArrowRight', shiftKey: true));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, false);
      expect(editor.state.selection.start.offset, 10);
      expect(editor.state.selection.end.offset, 11);
    });

    test('Releasing SHIFT collapses selection on next arrow move', () async {
      // Cria uma seleção estendida
      editor.state = editor.state.copyWith(
          selection: Selection(const Position(0, 10), const Position(0, 15)));

      // Simula a seta sem SHIFT
      // CORREÇÃO: Usar o método trigger
      overlay.triggerKeyDown(MockEventApi(key: 'ArrowRight', shiftKey: false));
      await Future.microtask(() {});

      // A seleção deve colapsar para o final da seleção anterior
      expect(editor.state.selection.isCollapsed, true);
      expect(editor.state.selection.start.offset, 15);
    });
  });
}