import 'package:canvas_text_editor/render/positioned_block.dart';

class PageLayout {
  final int pageIndex;
  final double yOrigin; // em px
  final List<PositionedBlock> blocks;
  const PageLayout({required this.pageIndex, required this.yOrigin, required this.blocks});
}
