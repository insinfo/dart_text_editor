import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/editor_state.dart';
import 'package:canvas_text_editor/core/block_node.dart';

/// Standalone operation-like class that deletes nodes by index.
class DeleteNodesOp {
  final List<int> nodeIndices;

  DeleteNodesOp(this.nodeIndices);

  EditorState apply(EditorState state) {
    final newNodes = List<BlockNode>.from(state.document.nodes);
    nodeIndices.sort((a, b) => b.compareTo(a)); // sort in descending order to avoid index shifting issues
    for (final index in nodeIndices) {
      newNodes.removeAt(index);
    }
    final newDoc = DocumentModel(newNodes);
    return EditorState(document: newDoc, selection: state.selection);
  }
}
