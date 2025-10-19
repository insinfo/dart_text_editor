import 'package:canvas_text_editor/core/delta.dart';
import 'package:canvas_text_editor/core/editor_command.dart';
import 'package:canvas_text_editor/core/editor_state.dart';
import 'package:canvas_text_editor/core/paragraph_attributes.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/transaction.dart';

class ApplyParagraphAttributesCommand extends EditorCommand {
  final ParagraphAttributes attributes;

  ApplyParagraphAttributesCommand(this.attributes);

  @override
  Transaction exec(EditorState state) {
    final delta = Delta();
    final selection = state.selection;
    final document = state.document;

    final startNodeIndex = selection.start.node;
    final endNodeIndex = selection.end.node;

    int totalRetained = 0;

    for (var i = 0; i < document.nodes.length; i++) {
      final node = document.nodes[i];
      final lengthWithSeparator = node.length + (i < document.nodes.length - 1 ? 1 : 0);

      if (i >= startNodeIndex && i <= endNodeIndex && node is ParagraphNode) {
        delta.retain(lengthWithSeparator, attributes: attributes.toMap());
      } else {
        delta.retain(lengthWithSeparator);
      }
      totalRetained += lengthWithSeparator;
    }
    
    final docLength = document.length;
    if (totalRetained < docLength) {
        delta.retain(docLength - totalRetained);
    }

    return Transaction.compat(delta, state.selection, state.selection);
  }
}