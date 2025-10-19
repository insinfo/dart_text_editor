import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:test/test.dart';

void main() {
  group('Selection', () {
    test('collapsed selection has start and end at the same position', () {
      final position = Position(0, 5);
      final selection = Selection.collapsed(position);
      expect(selection.start, position);
      expect(selection.end, position);
      expect(selection.isCollapsed, isTrue);
    });

    test('non-collapsed selection has different start and end positions', () {
      final start = Position(0, 0);
      final end = Position(0, 5);
      final selection = Selection(start, end);
      expect(selection.start, start);
      expect(selection.end, end);
      expect(selection.isCollapsed, isFalse);
    });

    test('equality and hash code work correctly for collapsed selections', () {
      final pos1 = Position(0, 5);
      final pos2 = Position(0, 5);
      final selection1 = Selection.collapsed(pos1);
      final selection2 = Selection.collapsed(pos2);
      expect(selection1, selection2);
      expect(selection1.hashCode, selection2.hashCode);
    });

    test('equality and hash code work correctly for non-collapsed selections',
        () {
      final start1 = Position(0, 0);
      final end1 = Position(0, 5);
      final start2 = Position(0, 0);
      final end2 = Position(0, 5);
      final selection1 = Selection(start1, end1);
      final selection2 = Selection(start2, end2);
      expect(selection1, selection2);
      expect(selection1.hashCode, selection2.hashCode);
    });

    test('equality and hash code work correctly for reversed selections', () {
      final start = Position(0, 0);
      final end = Position(0, 5);
      final selection1 = Selection(start, end);
      final selection2 = Selection(end, start); // Reversed
      expect(selection1, selection2);
      expect(selection1.hashCode, selection2.hashCode);
    });
  });
}
