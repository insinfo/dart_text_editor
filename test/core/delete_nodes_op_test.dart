import 'package:canvas_text_editor/core/delete_nodes_op.dart';
import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/editor_state.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/selection.dart';
import 'package:canvas_text_editor/core/position.dart';
import 'package:test/test.dart';

void main() {
  group('DeleteNodesOp', () {
    test('apply removes nodes from the document', () {
      final doc = DocumentModel([
        ParagraphNode([]),
        ParagraphNode([]),
        ParagraphNode([]),
      ]);
      final selection = Selection(Position(0, 0), Position(0, 0));
      final initialState = EditorState(document: doc, selection: selection);

      final op = DeleteNodesOp([0, 2]);
      final newState = op.apply(initialState);

      expect(newState.document.nodes.length, 1);
      expect(newState.document.nodes.first, initialState.document.nodes[1]);
    });
  });
}
