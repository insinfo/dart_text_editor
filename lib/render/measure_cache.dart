import '../core/inline_attributes.dart';
import 'metrics.dart';
import 'text_measurer_interface.dart';

class MeasureCache {
  final Map<String, Metrics> _cache = {};
  final TextMeasurerInterface _measurer;

  MeasureCache(this._measurer);

  void clear() {
    _cache.clear();
  }

  Metrics measure(String text, InlineAttributes attributes) {
    final key = '${text}_${_fontString(attributes)}';
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final metrics = _measurer.measure(text, attributes);
    _cache[key] = metrics;
    return metrics;
  }

  String _fontString(InlineAttributes attributes) {
    final fontSize = attributes.fontSize ?? 16; // Default font size
    final fontFamily = attributes
        .fontFamily; // Default font family is handled in InlineAttributes
    return '${attributes.italic ? 'italic' : 'normal'} ${attributes.bold ? 'bold' : 'normal'} ${fontSize}px $fontFamily';
  }
}
