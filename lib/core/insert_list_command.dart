import 'package:dart_text_editor/core/delta.dart';
import 'package:dart_text_editor/core/editor_command.dart';
import 'package:dart_text_editor/core/editor_state.dart';
import 'package:dart_text_editor/core/list_attributes.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/transaction.dart';

class InsertListCommand extends EditorCommand {
  final ListType listType;
  final int level;

  InsertListCommand({this.listType = ListType.unordered, this.level = 0});

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
      'list': {
        'type': listType.toString().split('.').last,
        'level': level,
      }
    });

    final newCaretPosition = state.document.positionFromOffset(startOffset + 1);
    final newSelection = Selection.collapsed(newCaretPosition);

    return Transaction.compat(delta, selection, newSelection);
  }
}
