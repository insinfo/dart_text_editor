import 'package:dart_text_editor/core/delta.dart';
import 'package:dart_text_editor/core/editor_command.dart';
import 'package:dart_text_editor/core/editor_state.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/transaction.dart';

class DeleteCommand implements EditorCommand {
  @override
  Transaction exec(EditorState state) {
    final selection = state.selection;
    final delta = Delta();

    final startOffset = state.document.getOffset(selection.start);
    final endOffset = state.document.getOffset(selection.end);

    if (!selection.isCollapsed) {
      delta.retain(startOffset);
      delta.delete(endOffset - startOffset);
    } else {
      // If selection is collapsed and at the end of the document, do nothing.
      if (startOffset == state.document.length) {
        return Transaction.compat(Delta(), selection, selection);
      }

      // If at the end of a paragraph (but not the end of the document),
      // delete the implicit newline character to merge with the next paragraph.
      // Otherwise, delete 1 character at the current position.
      delta.retain(startOffset);
      delta.delete(1);
    }

    // After a deletion, the selection is always collapsed at the start of the original selection.
    final newSelection = Selection.collapsed(selection.start);
    return Transaction.compat(delta, selection, newSelection);
  }
}
