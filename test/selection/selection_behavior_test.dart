import 'package:test/test.dart';
import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/text_run.dart';
import 'package:canvas_text_editor/core/inline_attributes.dart';
import 'package:canvas_text_editor/core/selection.dart';
import 'package:canvas_text_editor/core/position.dart';
import 'package:canvas_text_editor/editor.dart';
import '../mocks/manual_dom_api_mocks.dart';
import '../mocks/mock_text_measurer.dart';
import 'package:canvas_text_editor/render/measure_cache.dart';
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
      // CORREÇÃO: Usar o método trigger
      overlay.triggerMouseDown(MockMouseEventApi(clientX: 80, clientY: 10));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, true);
      // O Paginator mockado retornará uma posição baseada no X. 80 / 8 (largura mock) = 10
      expect(editor.state.selection.start.offset, 10);
    });

    test('Drag selection across lines selects correct text', () async {
      // CORREÇÃO: Usar os métodos trigger
      overlay.triggerMouseDown(MockMouseEventApi(clientX: 80, clientY: 10));
      await Future.microtask(() {});
      overlay.triggerMouseMove(MockMouseEventApi(clientX: 120, clientY: 40));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, false);
      expect(editor.state.selection.start.node, 0);
      expect(editor.state.selection.end.node, 1);
    });

    test('SHIFT + arrows extends selection from anchor', () async {
      editor.state = editor.state.copyWith(
        selection: Selection.collapsed(const Position(0, 10))
      );

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
        selection: Selection(const Position(0, 10), const Position(0, 15))
      );
      
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