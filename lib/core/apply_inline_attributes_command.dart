import 'package:canvas_text_editor/core/delta.dart';
import 'package:canvas_text_editor/core/editor_command.dart';
import 'package:canvas_text_editor/core/editor_state.dart';
import 'package:canvas_text_editor/core/inline_attributes.dart';
import 'package:canvas_text_editor/core/transaction.dart';

class ApplyInlineAttributesCommand extends EditorCommand {
  final InlineAttributes attributes;

  ApplyInlineAttributesCommand(this.attributes);

  @override
  Transaction exec(EditorState state) {
    final delta = Delta();
    final selection = state.selection;

    if (selection.isCollapsed) {
      return Transaction.compat(delta, state.selection, state.selection);
    }

    final startOffset = state.document.getOffset(selection.start);
    final endOffset = state.document.getOffset(selection.end);
    final length = endOffset - startOffset;

    if (startOffset > 0) {
      delta.retain(startOffset);
    }

    delta.retain(length, attributes: attributes.toMap());

    final remainingLength = state.document.length - endOffset;
    if (remainingLength > 0) {
      delta.retain(remainingLength);
    }

    return Transaction.compat(delta, state.selection, state.selection);
  }
}
