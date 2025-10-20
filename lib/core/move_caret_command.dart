// C:\MyDartProjects\canvas_text_editor\lib\core\move_caret_command.dart
import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/editor_command.dart';
import 'package:dart_text_editor/core/editor_state.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/transaction.dart';
import 'package:dart_text_editor/layout/paginator.dart';

enum CaretMovement {
  left,
  right,
  up,
  down,
  wordLeft,
  wordRight,
  lineStart,
  lineEnd,
}

class MoveCaretCommand implements EditorCommand {
  final CaretMovement direction;
  final Paginator paginator;
  final bool extend;

  MoveCaretCommand(this.direction, this.paginator, {this.extend = false});

  @override
  Transaction exec(EditorState state) {
    final sel = state.selection;
    final caret = sel.end;
    Position newPos = caret;

    // Se a seleção não estiver colapsada e não estamos estendendo,
    // colapsa a seleção na direção do movimento (sem mover o cursor).
    if (!sel.isCollapsed && !extend) {
      Position collapsePos;
      switch (direction) {
        case CaretMovement.left:
        case CaretMovement.wordLeft:
        case CaretMovement.lineStart:
          collapsePos = sel.start; // colapsa à esquerda
          break;
        default:
          collapsePos =
              sel.end; // colapsa à direita (right/wordRight/lineEnd/etc.)
      }
      // --- INÍCIO DA CORREÇÃO ---
      // Limpa a âncora do teclado para que a próxima seleção com SHIFT comece do zero.
      paginator.keyboardAnchor = null;
      // --- FIM DA CORREÇÃO ---
      return Transaction.compat(
        Transaction.emptyDelta,
        sel,
        Selection.collapsed(collapsePos),
      );
    }

    switch (direction) {
      case CaretMovement.left:
        newPos = (caret.offset > 0)
            ? Position(caret.node, caret.offset - 1)
            : (caret.node > 0
                ? Position(
                    caret.node - 1, state.document.nodes[caret.node - 1].length)
                : caret);
        paginator.desiredX = null; // reset coluna alvo vertical
        break;

      case CaretMovement.right:
        final len = state.document.nodes[caret.node].length;
        newPos = (caret.offset < len)
            ? Position(caret.node, caret.offset + 1)
            : (caret.node < state.document.nodes.length - 1
                ? Position(caret.node + 1, 0)
                : caret);
        paginator.desiredX = null; // reset coluna alvo vertical
        break;

      case CaretMovement.wordLeft:
        newPos =
            state.document.findWordBoundary(caret, SearchDirection.backward);
        paginator.desiredX = null;
        break;

      case CaretMovement.wordRight:
        newPos =
            state.document.findWordBoundary(caret, SearchDirection.forward);
        paginator.desiredX = null;
        break;

      case CaretMovement.lineStart:
        newPos = paginator.getLineStart(caret) ?? caret;
        paginator.desiredX = null;
        break;

      case CaretMovement.lineEnd:
        newPos = paginator.getLineEnd(caret) ?? caret;
        paginator.desiredX = null;
        break;

      case CaretMovement.up:
      case CaretMovement.down:
        final pos = paginator.screenPos(caret);
        if (pos != null) {
          paginator.desiredX ??=
              pos.x; // memoriza a coluna X na primeira seta vertical
          final newY = (direction == CaretMovement.up)
              ? pos.y - pos.height
              : pos.y + pos.height;
          newPos = paginator.getPositionFromScreen(paginator.desiredX!, newY) ??
              caret;
        }
        break;
    }

    if (!extend) {
      // seta não estendida: colapsa e limpa âncora
      paginator.keyboardAnchor = null;
      return Transaction.compat(
        Transaction.emptyDelta,
        sel,
        Selection.collapsed(newPos),
      );
    } else {
      // seta com SHIFT: ancora no primeiro movimento e expande até newPos
      paginator.keyboardAnchor ??= sel.start;
      return Transaction.compat(
        Transaction.emptyDelta,
        sel,
        Selection(paginator.keyboardAnchor!, newPos),
      );
    }
  }
}