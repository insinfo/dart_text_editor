import 'package:canvas_text_editor/core/delta.dart';
import 'package:canvas_text_editor/core/editor_command.dart';
import 'package:canvas_text_editor/core/editor_state.dart';
import 'package:canvas_text_editor/core/selection.dart';
import 'package:canvas_text_editor/core/transaction.dart';

class InsertTableCommand extends EditorCommand {
  final int rows;
  final int columns;

  InsertTableCommand({required this.rows, required this.columns});

  @override
  Transaction exec(EditorState state) {
    final delta = Delta();
    final selection = state.selection;

    final startOffset = state.document.getOffset(selection.start);
    final endOffset = state.document.getOffset(selection.end);

    if (startOffset > 0) {
      delta.retain(startOffset);
    }

    if (!selection.isCollapsed) {
      delta.delete(endOffset - startOffset);
    }

    delta.insert({
      'table': {
        'rows': rows,
        'columns': columns,
      }
    });

    final newCaretPosition = state.document.positionFromOffset(startOffset + 1);
    final newSelection = Selection.collapsed(newCaretPosition);

    return Transaction.compat(delta, selection, newSelection);
  }
}