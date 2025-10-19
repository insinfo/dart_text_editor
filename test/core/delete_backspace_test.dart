import 'package:dart_text_editor/core/backspace_command.dart';
import 'package:dart_text_editor/core/delete_command.dart';
import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/editor.dart'; // Corrected import
import 'package:dart_text_editor/core/insert_text_command.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/layout/paginator.dart';
import 'package:dart_text_editor/render/measure_cache.dart';
import 'package:dart_text_editor/core/undo_command.dart'; // Added import

import 'package:test/test.dart';
import '../mocks/manual_dom_api_mocks.dart';
import '../mocks/mock_text_measurer.dart';

void main() {
  group('Delete/Backspace Commands', () {
    late DocumentModel doc;
    late Editor editor;
    late MockCanvasElementApi mockCanvas;
    late Paginator paginator;

    setUp(() {
      mockCanvas = MockCanvasElementApi(width: 800, height: 600);
      paginator = Paginator(MeasureCache(MockTextMeasurer()));
      doc = DocumentModel([
        // Corrected DocumentModel instantiation
        ParagraphNode([TextRun(0, 'Line 1', InlineAttributes())]),
        ParagraphNode([TextRun(0, 'Line 2', InlineAttributes())]),
        ParagraphNode([TextRun(0, 'Line 3', InlineAttributes())]),
      ]);
      editor = Editor(mockCanvas, doc, paginator: paginator);
    });

    test(
        'Backspace at the beginning of a paragraph merges with the previous one',
        () {
      // Place caret at the beginning of "Line 2"
      editor.execute(InsertTextCommand(
          '')); // To update editor state with initial selection
      editor.state =
          editor.state.copyWith(selection: Selection.collapsed(Position(1, 0)));

      editor.execute(BackspaceCommand());

      expect(editor.state.document.nodes.length, 2);
      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          'Line 1Line 2');
      expect((editor.state.document.nodes[1] as ParagraphNode).text, 'Line 3');
      expect(editor.state.selection.start,
          Position(0, 6)); // Caret should be at the end of merged "Line 1"
    });

    test('Delete at the end of a paragraph merges with the next one', () {
      // Place caret at the end of "Line 1"
      editor.execute(InsertTextCommand(
          '')); // To update editor state with initial selection
      editor.state =
          editor.state.copyWith(selection: Selection.collapsed(Position(0, 6)));

      editor.execute(DeleteCommand());

      expect(editor.state.document.nodes.length, 2);
      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          'Line 1Line 2');
      expect((editor.state.document.nodes[1] as ParagraphNode).text, 'Line 3');
      expect(editor.state.selection.start,
          Position(0, 6)); // Caret should remain at the merge point
    });

    test('Backspace at the beginning of the document does nothing', () {
      // Place caret at the beginning of "Line 1"
      editor.execute(InsertTextCommand(
          '')); // To update editor state with initial selection
      editor.state =
          editor.state.copyWith(selection: Selection.collapsed(Position(0, 0)));
      final initialDoc = editor.state.document;

      editor.execute(BackspaceCommand());

      expect(editor.state.document.nodes.length, initialDoc.nodes.length);
      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          (initialDoc.nodes[0] as ParagraphNode).text);
      expect(editor.state.selection.start, Position(0, 0));
    });

    test('Delete at the end of the document does nothing', () {
      // Place caret at the end of "Line 3"
      editor.execute(InsertTextCommand(
          '')); // To update editor state with initial selection
      editor.state =
          editor.state.copyWith(selection: Selection.collapsed(Position(2, 6)));
      final initialDoc = editor.state.document;

      editor.execute(DeleteCommand());

      expect(editor.state.document.nodes.length, initialDoc.nodes.length);
      expect((editor.state.document.nodes[2] as ParagraphNode).text,
          (initialDoc.nodes[2] as ParagraphNode).text);
      expect(editor.state.selection.start, Position(2, 6));
    });
  });

  group('Undo Batching', () {
    late DocumentModel doc;
    late Editor editor;
    late MockCanvasElementApi mockCanvas;
    late Paginator paginator;

    setUp(() {
      mockCanvas = MockCanvasElementApi(width: 800, height: 600);
      doc = DocumentModel([
        ParagraphNode([TextRun(0, 'Initial text', InlineAttributes())]),
      ]);
      paginator = Paginator(MeasureCache(MockTextMeasurer()));
      editor = Editor(mockCanvas, doc, paginator: paginator);
    });

    test(
        'typing multiple characters in quick succession creates a single undo transaction',
        () async {
      editor.state = editor.state.copyWith(
          selection:
              Selection.collapsed(Position(0, 12))); // Place caret at end

      // Simulate typing "hello" quickly
      editor.execute(InsertTextCommand('h'));
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(InsertTextCommand('e'));
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(InsertTextCommand('l'));
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(InsertTextCommand('l'));
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(InsertTextCommand('o'));

      // Wait for the batching timer to finalize
      await Future.delayed(Duration(milliseconds: 200));

      expect(editor.state.undoStack.length,
          1); // Should be one transaction for "hello"
      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          'Initial texthello');

      editor.execute(UndoCommand());
      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          'Initial text');
    });

    test(
        'deleting multiple characters in quick succession creates a single undo transaction',
        () async {
      editor.state = editor.state.copyWith(
          document: DocumentModel([
            ParagraphNode(
                [TextRun(0, 'Initial text to delete', InlineAttributes())]),
          ]),
          selection:
              Selection.collapsed(Position(0, 22))); // Place caret at end

      // Simulate backspacing "delete" quickly
      editor.execute(BackspaceCommand()); // e
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(BackspaceCommand()); // t
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(BackspaceCommand()); // e
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(BackspaceCommand()); // l
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(BackspaceCommand()); // e
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(BackspaceCommand()); // d

      // Wait for the batching timer to finalize
      await Future.delayed(Duration(milliseconds: 200));

      expect(editor.state.undoStack.length,
          1); // Should be one transaction for "delete"
      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          'Initial text to ');

      editor.execute(UndoCommand());
      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          'Initial text to delete');
    });

    test('a pause in typing creates separate undo transactions', () async {
      editor.state = editor.state
          .copyWith(selection: Selection.collapsed(Position(0, 12)));

      editor.execute(InsertTextCommand('h'));
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(InsertTextCommand('e'));
      await Future.delayed(
          Duration(milliseconds: 200)); // Pause longer than batching timer
      editor.execute(InsertTextCommand('l'));
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(InsertTextCommand('l'));

      await Future.delayed(
          Duration(milliseconds: 200)); // Wait for the last batch to finalize

      expect(editor.state.undoStack.length,
          2); // Should be two transactions: "he" and "ll"
      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          'Initial texthell');

      editor.execute(UndoCommand());
      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          'Initial texthe');

      editor.execute(UndoCommand());
      expect((editor.state.document.nodes[0] as ParagraphNode).text,
          'Initial text');
    });
  });
}
