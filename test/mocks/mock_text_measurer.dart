import 'package:canvas_text_editor/core/inline_attributes.dart';
import 'package:canvas_text_editor/render/metrics.dart';
import 'package:canvas_text_editor/render/text_measurer_interface.dart';

class MockTextMeasurer implements TextMeasurerInterface {
  @override
  Metrics measure(String text, InlineAttributes attributes) {
    // Return a mock Metrics object with a fixed width for every character.
    return MockMetrics(width: text.length * 100.0, height: attributes.fontSize ?? 16.0);
  }
}

class MockMetrics implements Metrics {
  @override
  final double width;
  @override
  final double height;

  MockMetrics({required this.width, this.height = 16.0});
}