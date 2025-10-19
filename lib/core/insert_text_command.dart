// Arquivo: lib/core/insert_text_command.dart (CORRIGIDO)
import 'package:dart_text_editor/core/delta.dart';
import 'package:dart_text_editor/core/editor_command.dart';
import 'package:dart_text_editor/core/editor_state.dart';
import 'package:dart_text_editor/core/transaction.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';

class InsertTextCommand implements EditorCommand {
  final String text;

  InsertTextCommand(this.text);

  @override
  Transaction exec(EditorState state) {
    final selection = state.selection;
    final delta = Delta();

    final startOffset = state.document.getOffset(selection.start);
    final endOffset = state.document.getOffset(selection.end);

    if (startOffset > 0) {
      delta.retain(startOffset);
    }

    if (!selection.isCollapsed) {
      delta.delete(endOffset - startOffset);
    }

    // CORREÇÃO B5: Usa os atributos de digitação do estado atual ao inserir texto.
    // O delta agora carrega os atributos junto com o texto.
    delta.insert(text, attributes: state.typingAttributes.toMap());

    // O DocumentModel.apply cuidará de calcular a nova posição do cursor.
    // A seleção final será determinada pelo resultado de document.apply.
    final newPosition =
        Position(selection.start.node, selection.start.offset + text.length);
    final newSelection = Selection.collapsed(newPosition);

    return Transaction.compat(delta, selection, newSelection);
  }
}
