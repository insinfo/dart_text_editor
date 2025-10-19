import 'package:canvas_text_editor/core/inline_attributes.dart';
import 'package:test/test.dart';

void main() {
  group('InlineAttributes', () {
    test('merge returns a new instance with the correct values', () {
      final initial = InlineAttributes();
      final other = InlineAttributes(
        bold: true,
        underline: true,
        fontFamily: 'Arial',
      );

      final merged = initial.merge(other);

      expect(merged.bold, isTrue);
      expect(merged.underline, isTrue);
      expect(merged.fontFamily, 'Arial');
    });
  });
}
