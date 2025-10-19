import 'package:canvas_text_editor/core/delta.dart';
import 'package:canvas_text_editor/core/editor_command.dart';
import 'package:canvas_text_editor/core/editor_state.dart';

import 'package:canvas_text_editor/core/selection.dart';
import 'package:canvas_text_editor/core/transaction.dart';

class BackspaceCommand implements EditorCommand {
  @override
  Transaction exec(EditorState state) {
    final selection = state.selection;
    final delta = Delta();

    final startOffset = state.document.getOffset(selection.start);
    final endOffset = state.document.getOffset(selection.end);

    if (!selection.isCollapsed) {
      delta.retain(startOffset);
      delta.delete(endOffset - startOffset);
      final newSelection = Selection.collapsed(selection.start);
      return Transaction.compat(delta, selection, newSelection);
    } else {
      if (startOffset == 0) {
        // At the beginning of the document, do nothing
        return Transaction.compat(Delta(), selection, selection);
      }

      // Calculate the position before the current caret
      final positionBeforeCaret = state.document.positionFromOffset(startOffset - 1);

      delta.retain(startOffset - 1);
      delta.delete(1);

      final newSelection = Selection.collapsed(positionBeforeCaret);
      return Transaction.compat(delta, selection, newSelection);
    }
  }
}
