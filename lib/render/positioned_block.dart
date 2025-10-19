import 'package:dart_text_editor/core/block_node.dart';

class PositionedBlock {
  final BlockNode node;
  final int nodeIndex;
  final double x;
  final double y;
  final double width;
  final double height;

  PositionedBlock({
    required this.node,
    required this.nodeIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}
