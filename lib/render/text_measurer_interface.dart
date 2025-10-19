import 'package:dart_text_editor/core/inline_attributes.dart';
import 'metrics.dart';

abstract class TextMeasurerInterface {
  Metrics measure(String text, InlineAttributes attributes);
}
