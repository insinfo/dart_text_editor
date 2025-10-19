// Arquivo: lib/core/selection.dart (COMPLETO E CORRIGIDO)
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/document_model.dart';

class Selection {
  final Position start;
  final Position end;

  Selection(Position p1, Position p2)
      : start = (p1 < p2 || p1 == p2) ? p1 : p2,
        end = (p1 < p2 || p1 == p2) ? p2 : p1;

  factory Selection.collapsed(Position p) => Selection(p, p);

  bool get isCollapsed => start == end;

  Selection collapse([bool toStart = false]) {
    return Selection.collapsed(toStart ? start : end);
  }

  Selection expandToWordBoundaries(DocumentModel document) {
    if (isCollapsed) {
      final newStart =
          document.findWordBoundary(start, SearchDirection.backward);
      final newEnd = document.findWordBoundary(end, SearchDirection.forward);
      return Selection(newStart, newEnd);
    } else {
      return this;
    }
  }

  Selection get normalized => Selection(start, end);

  @override
  bool operator ==(Object other) =>
      other is Selection && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
