import 'package:canvas_text_editor/core/delta.dart';
import 'package:canvas_text_editor/core/editor_command.dart';
import 'package:canvas_text_editor/core/editor_state.dart';
import 'package:canvas_text_editor/core/position.dart';
import 'package:canvas_text_editor/core/selection.dart';
import 'package:canvas_text_editor/core/transaction.dart';

class EnterCommand implements EditorCommand {
  @override
  Transaction exec(EditorState state) {
    final selection = state.selection;
    final delta = Delta();

    final startOffset = state.document.getOffset(selection.start);
    final endOffset = state.document.getOffset(selection.end);

    delta.retain(startOffset);

    if (!selection.isCollapsed) {
      delta.delete(endOffset - startOffset);
    }

    // Insert a newline character. The DocumentModel will interpret this as a paragraph split.
    delta.insert('\n');

    // The new position will be at the start of the new paragraph (node index + 1, offset 0)
    // DocumentModel.apply will return the correct new caret position.
    final newSelection = Selection.collapsed(Position(selection.start.node + 1, 0));

    return Transaction.compat(delta, selection, newSelection);
  }
}
