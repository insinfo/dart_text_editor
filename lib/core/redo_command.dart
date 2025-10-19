import 'package:canvas_text_editor/core/delta.dart';
import 'package:canvas_text_editor/core/editor_command.dart';
import 'package:canvas_text_editor/core/editor_state.dart';

import 'package:canvas_text_editor/core/transaction.dart';

/// A marker command to trigger the redo functionality in the editor.
class RedoCommand implements EditorCommand {
  @override
  Transaction exec(EditorState state) {
    // This command is handled specially by the Editor.
    // It does not produce a transaction on its own.
    return Transaction.compat(Delta(), state.selection, state.selection);
  }
}
