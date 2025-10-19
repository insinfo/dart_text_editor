import 'dart:html';

class RasterCache {
  final Map<int, CanvasElement> _cache = {};

  void put(int pageIndex, CanvasElement canvas) {
    _cache[pageIndex] = canvas;
  }

  CanvasElement? get(int pageIndex) {
    return _cache[pageIndex];
  }

  void clear() {
    _cache.clear();
  }
}
