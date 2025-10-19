// Arquivo: C:\MyDartProjects\canvas_text_editor\lib\core\backspace_command.dart
import "package:dart_text_editor/core/delta.dart";
import "package:dart_text_editor/core/editor_command.dart";
import "package:dart_text_editor/core/editor_state.dart";
import "package:dart_text_editor/core/selection.dart";
import "package:dart_text_editor/core/position.dart";
import "package:dart_text_editor/core/transaction.dart";

class BackspaceCommand implements EditorCommand {
  @override
  Transaction exec(EditorState state) {
    final sel = state.selection;
    final delta = Delta();

    final startOffset = state.document.getOffset(sel.start);
    final endOffset = state.document.getOffset(sel.end);

    // Seleção não colapsada: apaga o intervalo.
    if (!sel.isCollapsed) {
      delta.retain(startOffset);
      delta.delete(endOffset - startOffset);
      return Transaction.compat(delta, sel, Selection.collapsed(sel.start));
    }

    // Início absoluto do documento: nada a fazer.
    if (startOffset == 0) {
      return Transaction.compat(Delta(), sel, sel);
    }

    // FIX: início de parágrafo -> deletar a "quebra" entre nós (merge)
    // Em vez de retain(startOffset), usamos startOffset - 1 para que a
    // deleção atravesse o limite entre os parágrafos e o DocumentModel faça o merge.
    if (sel.start.offset == 0 && sel.start.node > 0) {
      delta.retain(startOffset - 1);
      delta.delete(1);

      final prevLen = state.document.nodes[sel.start.node - 1].length;
      final newCaret = Position(sel.start.node - 1, prevLen);
      return Transaction.compat(delta, sel, Selection.collapsed(newCaret));
    }

    // Caso geral: apagar o caractere imediatamente anterior ao caret.
    delta.retain(startOffset - 1);
    delta.delete(1);
    final newCaret = state.document.positionFromOffset(startOffset - 1);
    return Transaction.compat(delta, sel, Selection.collapsed(newCaret));
  }
}
