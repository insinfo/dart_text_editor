import 'package:canvas_text_editor/core/backspace_command.dart';
import 'package:canvas_text_editor/core/delete_command.dart';
import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/editor.dart'; // Corrected import
import 'package:canvas_text_editor/core/insert_text_command.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/position.dart';
import 'package:canvas_text_editor/core/selection.dart';
import 'package:canvas_text_editor/core/text_run.dart';
import 'package:canvas_text_editor/core/inline_attributes.dart';
import 'package:canvas_text_editor/layout/paginator.dart';
import 'package:canvas_text_editor/render/measure_cache.dart';
import 'package:canvas_text_editor/core/undo_command.dart'; // Added import
import 'package:canvas_text_editor/util/dom_api.dart';
import 'package:test/test.dart';
import '../mocks/mock_text_measurer.dart';

// Mock CanvasElement and CanvasRenderingContext2D
class MockCanvasElement implements CanvasElementApi {
  @override
  int width;
  @override
  int height;
  @override
  MockCanvasRenderingContext2D context2D = MockCanvasRenderingContext2D();

  MockCanvasElement({this.width = 800, this.height = 600});

  @override
  RectangleApi getBoundingClientRect() => MockRectangle();
  
  @override
  Stream<MouseEventApi> get onClick => Stream.empty();
}

class MockCanvasRenderingContext2D implements CanvasRenderingContext2DApi {
  @override
  void scale(num x, num y) {}
  @override
  void clearRect(num x, num y, num w, num h) {}
  @override
  void fillText(String text, num x, num y) {}
  @override
  void fillRect(num x, num y, num w, num h) {}
  @override
  void beginPath() {}
  @override
  void rect(num x, num y, num w, num h) {}
  @override
  void clip() {}
  @override
  void save() {}
  @override
  void restore() {}
  @override
  set font(String value) {}
  @override
  set fillStyle(Object value) {}
  @override
  set strokeStyle(Object value) {}
  @override
  set lineWidth(num value) {}
  @override
  void moveTo(num x, num y) {}
  @override
  void lineTo(num x, num y) {}
  @override
  void stroke() {}
  @override
  set textBaseline(String value) {}
  @override
  void translate(num x, num y) {}
  @override
  void strokeRect(num x, num y, num w, num h) {}
  @override
  double measureTextWidth(String text) => text.length * 8.0; // Mock measurement
}

class MockRectangle implements RectangleApi {
  @override
  double get left => 0;
  @override
  double get top => 0;
  @override
  double get width => 800;
  @override
  double get height => 600;
}


void main() {
  group('Delete/Backspace Commands', () {
    late DocumentModel doc;
    late Editor editor;
    late MockCanvasElement mockCanvas;
    late Paginator paginator;

    setUp(() {
      mockCanvas = MockCanvasElement(width: 800, height: 600);
      paginator = Paginator(MeasureCache(MockTextMeasurer()));
      doc = DocumentModel([ // Corrected DocumentModel instantiation
        ParagraphNode([TextRun(0, 'Line 1', InlineAttributes())]),
        ParagraphNode([TextRun(0, 'Line 2', InlineAttributes())]),
        ParagraphNode([TextRun(0, 'Line 3', InlineAttributes())]),
      ]);
      editor = Editor(mockCanvas, doc, paginator: paginator);
    });

    test('Backspace at the beginning of a paragraph merges with the previous one', () {
      // Place caret at the beginning of "Line 2"
      editor.execute(InsertTextCommand('')); // To update editor state with initial selection
      editor.state = editor.state.copyWith(selection: Selection.collapsed(Position(1, 0)));

      editor.execute(BackspaceCommand());

      expect(editor.state.document.nodes.length, 2);
      expect((editor.state.document.nodes[0] as ParagraphNode).text, 'Line 1Line 2');
      expect((editor.state.document.nodes[1] as ParagraphNode).text, 'Line 3');
      expect(editor.state.selection.start, Position(0, 6)); // Caret should be at the end of merged "Line 1"
    });

    test('Delete at the end of a paragraph merges with the next one', () {
      // Place caret at the end of "Line 1"
      editor.execute(InsertTextCommand('')); // To update editor state with initial selection
      editor.state = editor.state.copyWith(selection: Selection.collapsed(Position(0, 6)));

      editor.execute(DeleteCommand());

      expect(editor.state.document.nodes.length, 2);
      expect((editor.state.document.nodes[0] as ParagraphNode).text, 'Line 1Line 2');
      expect((editor.state.document.nodes[1] as ParagraphNode).text, 'Line 3');
      expect(editor.state.selection.start, Position(0, 6)); // Caret should remain at the merge point
    });

    test('Backspace at the beginning of the document does nothing', () {
      // Place caret at the beginning of "Line 1"
      editor.execute(InsertTextCommand('')); // To update editor state with initial selection
      editor.state = editor.state.copyWith(selection: Selection.collapsed(Position(0, 0)));
      final initialDoc = editor.state.document;

      editor.execute(BackspaceCommand());

      expect(editor.state.document.nodes.length, initialDoc.nodes.length);
      expect((editor.state.document.nodes[0] as ParagraphNode).text, (initialDoc.nodes[0] as ParagraphNode).text);
      expect(editor.state.selection.start, Position(0, 0));
    });

    test('Delete at the end of the document does nothing', () {
      // Place caret at the end of "Line 3"
      editor.execute(InsertTextCommand('')); // To update editor state with initial selection
      editor.state = editor.state.copyWith(selection: Selection.collapsed(Position(2, 6)));
      final initialDoc = editor.state.document;

      editor.execute(DeleteCommand());

      expect(editor.state.document.nodes.length, initialDoc.nodes.length);
      expect((editor.state.document.nodes[2] as ParagraphNode).text, (initialDoc.nodes[2] as ParagraphNode).text);
      expect(editor.state.selection.start, Position(2, 6));
    });
  });

  group('Undo Batching', () {
    late DocumentModel doc;
    late Editor editor;
    late MockCanvasElement mockCanvas;
    late Paginator paginator;

    setUp(() {
      mockCanvas = MockCanvasElement(width: 800, height: 600);
      doc = DocumentModel([
        ParagraphNode([TextRun(0, 'Initial text', InlineAttributes())]),
      ]);
      paginator = Paginator(MeasureCache(MockTextMeasurer()));
      editor = Editor(mockCanvas, doc, paginator: paginator);
    });

    test('typing multiple characters in quick succession creates a single undo transaction', () async {
      editor.state = editor.state.copyWith(selection: Selection.collapsed(Position(0, 12))); // Place caret at end

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

      expect(editor.state.undoStack.length, 1); // Should be one transaction for "hello"
      expect((editor.state.document.nodes[0] as ParagraphNode).text, 'Initial texthello');

      editor.execute(UndoCommand());
      expect((editor.state.document.nodes[0] as ParagraphNode).text, 'Initial text');
    });

    test('deleting multiple characters in quick succession creates a single undo transaction', () async {
      editor.state = editor.state.copyWith(
          document: DocumentModel([
            ParagraphNode([TextRun(0, 'Initial text to delete', InlineAttributes())]),
          ]),
          selection: Selection.collapsed(Position(0, 22))); // Place caret at end

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

      expect(editor.state.undoStack.length, 1); // Should be one transaction for "delete"
      expect((editor.state.document.nodes[0] as ParagraphNode).text, 'Initial text to ');

      editor.execute(UndoCommand());
      expect((editor.state.document.nodes[0] as ParagraphNode).text, 'Initial text to delete');
    });

    test('a pause in typing creates separate undo transactions', () async {
      editor.state = editor.state.copyWith(selection: Selection.collapsed(Position(0, 12)));

      editor.execute(InsertTextCommand('h'));
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(InsertTextCommand('e'));
      await Future.delayed(Duration(milliseconds: 200)); // Pause longer than batching timer
      editor.execute(InsertTextCommand('l'));
      await Future.delayed(Duration(milliseconds: 50));
      editor.execute(InsertTextCommand('l'));

      await Future.delayed(Duration(milliseconds: 200)); // Wait for the last batch to finalize

      expect(editor.state.undoStack.length, 2); // Should be two transactions: "he" and "ll"
      expect((editor.state.document.nodes[0] as ParagraphNode).text, 'Initial texthell');

      editor.execute(UndoCommand());
      expect((editor.state.document.nodes[0] as ParagraphNode).text, 'Initial texthe');

      editor.execute(UndoCommand());
      expect((editor.state.document.nodes[0] as ParagraphNode).text, 'Initial text');
    });
  });
}