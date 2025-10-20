// Arquivo: C:\MyDartProjects\canvas_text_editor\test\interaction\selection_and_navigation_test.dart
import 'dart:async';
import 'package:dart_text_editor/core/document_model.dart';

import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/editor.dart';
import 'package:dart_text_editor/layout/page_constraints.dart';
import 'package:dart_text_editor/layout/paragraph_layouter.dart';
import 'package:dart_text_editor/render/measure_cache.dart';
import 'package:test/test.dart';
import '../mocks/manual_dom_api_mocks.dart';
import '../mocks/mock_text_measurer.dart';

void main() {
  group('Selection and Navigation Tests', () {
    late DocumentModel document;
    late Editor editor;
    late MockCanvasElementApi canvas;
    late MockDivElementApi overlay;
    late MockTextMeasurer textMeasurer;

    setUp(() {
      document = DocumentModel([
        ParagraphNode([
          TextRun(
              0, 'Line one is here.', const InlineAttributes()), // length 17
        ]),
        ParagraphNode([
          TextRun(
              0, 'Line two is here.', const InlineAttributes()), // length 17
        ])
      ]);
      canvas = MockCanvasElementApi();
      overlay = MockDivElementApi();
      textMeasurer = MockTextMeasurer();
      editor = Editor(
        canvas,
        document,
        measureCache: MeasureCache(textMeasurer),
        overlay: overlay,
      );
      // Simula um layout inicial para que o paginator tenha dados
      editor.paint();
    });

    test('SHIFT + Right Arrow extends selection by one character', () async {
      editor.state = editor.state
          .copyWith(selection: Selection.collapsed(const Position(0, 5)));

      overlay.triggerKeyDown(MockEventApi(key: 'ArrowRight', shiftKey: true));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, isFalse);
      expect(editor.state.selection.start, const Position(0, 5));
      expect(editor.state.selection.end, const Position(0, 6));
    });

    test('Mouse drag creates a valid selection', () async {
      // Posição inicial do mouse (margem 57 + 5 chars * 8 de largura = 97)
      overlay.triggerMouseDown(MockMouseEventApi(clientX: 97, clientY: 70));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, isTrue);
      expect(editor.state.selection.start, const Position(0, 5));

      // Posição final do mouse (margem 57 + 10 chars * 8 de largura = 137)
      overlay.triggerMouseMove(MockMouseEventApi(clientX: 137, clientY: 70));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, isFalse);
      expect(editor.state.selection.start, const Position(0, 5));
      expect(editor.state.selection.end, const Position(0, 10));
    });

    test('Home key moves caret to start of the line', () async {
      editor.state = editor.state
          .copyWith(selection: Selection.collapsed(const Position(0, 10)));

      overlay.triggerKeyDown(MockEventApi(key: 'Home'));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, isTrue);
      expect(editor.state.selection.start, const Position(0, 0));
    });

    test('End key moves caret to end of the line', () async {
      editor.state = editor.state
          .copyWith(selection: Selection.collapsed(const Position(0, 5)));

      overlay.triggerKeyDown(MockEventApi(key: 'End'));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, isTrue);
      expect(editor.state.selection.start, const Position(0, 17));
    });

    test('SHIFT + Home selects from caret to line start', () async {
      editor.state = editor.state
          .copyWith(selection: Selection.collapsed(const Position(0, 10)));

      overlay.triggerKeyDown(MockEventApi(key: 'Home', shiftKey: true));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, isFalse);
      expect(editor.state.selection.start, const Position(0, 0));
      expect(editor.state.selection.end, const Position(0, 10));
    });

    test('Double click selects a word', () async {
      // --- INÍCIO DA CORREÇÃO ---
      // Simula um duplo clique no meio da palavra "one" (offset 6)
      // clientX = margem_padrão (57) + (offset * largura_char_mock) = 57 + (6 * 8) = 105
      overlay.triggerDoubleClick(MockMouseEventApi(clientX: 105, clientY: 70));
      await Future.microtask(() {});
      // --- FIM DA CORREÇÃO ---

      expect(editor.state.selection.isCollapsed, isFalse);
      expect(editor.state.selection.start, const Position(0, 5));
      expect(editor.state.selection.end, const Position(0, 8)); // "one"
    });

    test('Inserting spaces at line end wraps to the next line', () async {
      final shortDoc = DocumentModel([
        ParagraphNode(
            [TextRun(0, 'word1 word2', const InlineAttributes())]), // 11 chars
      ]);
      final editorWithShortLine = Editor(
        canvas,
        shortDoc,
        // Mock com largura de char de 10 para facilitar o cálculo (10 chars = 100px)
        measureCache: MeasureCache(MockTextMeasurer(charWidth: 10)),
        overlay: overlay,
      );
      // Força um layout com largura de 100px
      editorWithShortLine.paginator
          .paginate(shortDoc, PageConstraints(width: 100, height: 500));
      editorWithShortLine.state = editorWithShortLine.state
          .copyWith(selection: Selection.collapsed(const Position(0, 11)));

      // Inserir um espaço deve quebrar a linha
      overlay.triggerKeyDown(MockEventApi(key: ' '));
      await Future.microtask(() {});

      // Verifica se a quebra de linha ocorreu no layout
      final layoutResult = editorWithShortLine.paginator.lastPaginatedPages;
      final paragraphLayout = layoutResult.first.blocks.first;
      final layouter = editorWithShortLine.paginator.layouter;
      final lines = layouter
          .layout(paragraphLayout.node as ParagraphNode,
              PageConstraints(width: 100, height: 500))
          .lines;

      expect(lines.length, 2,
          reason: "The paragraph should now have two lines");
      expect(lines[0].spans.last.run.text, " ",
          reason: "The last span of the first line should be a space.");
      expect(lines[1].spans.first.run.text, "word2",
          reason: "The first span of the second line should be 'word2'.");
    });

    test('Double click on a word selects only that word', () async {
      // --- INÍCIO DA CORREÇÃO ---
      // O texto é 'Line one is here.'. Selecionaremos "Line".
      // clientX = margem + (offset * largura_char) = 57 + (2 * 8) = 73
      overlay.triggerDoubleClick(MockMouseEventApi(clientX: 73, clientY: 70));
      await Future.microtask(() {});

      expect(editor.state.selection.isCollapsed, isFalse);
      expect(editor.state.selection.start,
          const Position(0, 0)); // "Line" começa no offset 0
      expect(editor.state.selection.end,
          const Position(0, 4)); // "Line" termina no offset 4
      // --- FIM DA CORREÇÃO ---
    });

    test(
        'SHIFT + Right Arrow, then Right Arrow without SHIFT, then SHIFT + Left Arrow',
        () async {
      // 1. Posição inicial
      editor.state = editor.state
          .copyWith(selection: Selection.collapsed(const Position(0, 5)));

      // 2. SHIFT + Direita
      overlay.triggerKeyDown(MockEventApi(key: 'ArrowRight', shiftKey: true));
      await Future.microtask(() {});
      expect(editor.state.selection,
          Selection(const Position(0, 5), const Position(0, 6)));

      // 3. Direita (sem SHIFT) -> Colapsa a seleção
      overlay.triggerKeyDown(MockEventApi(key: 'ArrowRight', shiftKey: false));
      await Future.microtask(() {});
      expect(editor.state.selection.isCollapsed, isTrue);
      expect(editor.state.selection.start,
          const Position(0, 6)); // Colapsa no final

      // 4. Inicia nova seleção com SHIFT + Esquerda
      overlay.triggerKeyDown(MockEventApi(key: 'ArrowLeft', shiftKey: true));
      await Future.microtask(() {});
      expect(editor.state.selection,
          Selection(const Position(0, 5), const Position(0, 6)));
    });

    test('space at the beginning of a wrapped line is visible', () {
      // 10 chars de 10px cada cabem perfeitamente
      final text = 'Line with nine chars.'; // 21 chars
      final node = ParagraphNode([TextRun(0, text, InlineAttributes())]);
      // Largura para 20 caracteres
      final constraints = PageConstraints(width: 200, height: 100);

      // Mock com charWidth de 10 para facilitar
      final layouter =
          ParagraphLayouter(MeasureCache(MockTextMeasurer(charWidth: 10)));
      final result = layouter.layout(node, constraints);

      // Deve quebrar após 'nine '
      expect(result.lines.length, 2);

      // A segunda linha deve começar com 'chars.'
      final secondLineFirstSpan = result.lines[1].spans.first;
      expect(secondLineFirstSpan.hidden, isFalse);
    });

    //end
  });
}
