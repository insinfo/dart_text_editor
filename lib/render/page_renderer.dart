import 'package:dart_text_editor/render/raster_cache.dart';
import 'package:dart_text_editor/render/editor_theme.dart';

abstract class PageRenderer {
  final RasterCache rasterCache;
  final EditorTheme theme;

  PageRenderer({required this.rasterCache, required this.theme});

  // TODO: Implement page rendering logic
}
