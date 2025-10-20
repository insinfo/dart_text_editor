// Arquivo: C:\MyDartProjects\canvas_text_editor\lib\render\raster_cache.dart

import 'package:dart_text_editor/util/dom_api.dart';

class RasterCache {
  final Map<int, CanvasElementApi> _cache = {};

  void put(int pageIndex, CanvasElementApi canvas) {
    _cache[pageIndex] = canvas;
  }

  CanvasElementApi? get(int pageIndex) {
    return _cache[pageIndex];
  }

  void clear() {
    _cache.clear();
  }
}
