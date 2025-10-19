import 'package:dart_text_editor/core/rectangle.dart';
import 'package:test/test.dart';

void main() {
  group('Rectangle', () {
    test('constructor sets the values correctly', () {
      final rect = Rectangle(10, 20, 30, 40);

      expect(rect.left, 10);
      expect(rect.top, 20);
      expect(rect.right, 30);
      expect(rect.bottom, 40);
    });
  });
}
