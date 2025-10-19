// Arquivo: lib/core/move_caret_command.dart (COMPLETO E CORRIGIDO)
import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/editor_command.dart';
import 'package:canvas_text_editor/core/editor_state.dart';
import 'package:canvas_text_editor/core/position.dart';
import 'package:canvas_text_editor/core/selection.dart';
import 'package:canvas_text_editor/core/transaction.dart';
import 'package:canvas_text_editor/layout/paginator.dart';

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

  static Position? _keyboardAnchor;
  static double? _desiredX;

  MoveCaretCommand(this.direction, this.paginator, {this.extend = false});

  @override
  Transaction exec(EditorState state) {
    final sel = state.selection;
    final caret = sel.end;
    Position newPos = caret;
      // Collapse selection to start or end if not extending and selection is not collapsed
  if (!extend && !sel.isCollapsed) {
    switch (direction) {
      case CaretMovement.left:
      case CaretMovement.up:
      case CaretMovement.wordLeft:
      case CaretMovement.lineStart:
        // Collapse to start of selection
        return Transaction.emptyDelta(sel, sel.collapse(true));
      default:
        // Collapse to end of selection
        return Transaction.emptyDelta(sel, sel.collapse());
    }
  }


    switch (direction) {
      case CaretMovement.left:
        newPos = (caret.offset > 0)
            ? Position(caret.node, caret.offset - 1)
            : (caret.node > 0
                ? Position(
                    caret.node - 1, state.document.nodes[caret.node - 1].length)
                : caret);
        _desiredX = null;
        break;
      case CaretMovement.right:
        final len = state.document.nodes[caret.node].length;
        newPos = (caret.offset < len)
            ? Position(caret.node, caret.offset + 1)
            : (caret.node < state.document.nodes.length - 1
                ? Position(caret.node + 1, 0)
                : caret);
        _desiredX = null;
        break;
      case CaretMovement.wordLeft:
        newPos =
            state.document.findWordBoundary(caret, SearchDirection.backward);
        _desiredX = null;
        break;
      case CaretMovement.wordRight:
        newPos =
            state.document.findWordBoundary(caret, SearchDirection.forward);
        _desiredX = null;
        break;
      case CaretMovement.lineStart:
        newPos = paginator.getLineStart(caret) ?? caret;
        _desiredX = null;
        break;
      case CaretMovement.lineEnd:
        newPos = paginator.getLineEnd(caret) ?? caret;
        _desiredX = null;
        break;
      case CaretMovement.up:
      case CaretMovement.down:
        final pos = paginator.screenPos(caret);
        if (pos != null) {
          _desiredX ??= pos.x;
          final newY = direction == CaretMovement.up
              ? pos.y - pos.height
              : pos.y + pos.height;
          newPos = paginator.getPositionFromScreen(_desiredX!, newY) ?? caret;
        }
        break;
    }

    if (!extend) {
      _keyboardAnchor = null;
      return Transaction.compat(
          Transaction.emptyDelta, sel, Selection.collapsed(newPos));
    } else {
      _keyboardAnchor ??= sel.start;
      return Transaction.compat(
          Transaction.emptyDelta, sel, Selection(_keyboardAnchor!, newPos));
    }
  }
}
