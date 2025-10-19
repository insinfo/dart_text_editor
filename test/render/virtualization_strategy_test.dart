import 'package:canvas_text_editor/render/virtualization_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('VirtualizationStrategy', () {
    test('getVisiblePages returns the correct pages', () {
      final strategy = VirtualizationStrategy();
      final pages = strategy.getVisiblePages(1200, 800, 800);

      expect(pages, [1, 2, 3]);
    });
  });
}
