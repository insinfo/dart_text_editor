import 'package:dart_text_editor/core/delta.dart';
import 'package:dart_text_editor/core/editor_command.dart';
import 'package:dart_text_editor/core/editor_state.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/transaction.dart';

class DeleteSelectionCommand implements EditorCommand {
  @override
  Transaction exec(EditorState state) {
    final selection = state.selection;

    if (selection.isCollapsed) {
      return Transaction.compat(Delta(), selection, selection);
    }

    final startOffset = state.document.getOffset(selection.start);
    final endOffset = state.document.getOffset(selection.end);
    final lengthToDelete = endOffset - startOffset;

    final delta = Delta();
    delta.retain(startOffset);
    delta.delete(lengthToDelete);

    final newSelection = Selection.collapsed(selection.start);
    return Transaction.compat(delta, selection, newSelection);
  }
}
