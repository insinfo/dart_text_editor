import 'package:canvas_text_editor/core/block_kind.dart';
import 'package:canvas_text_editor/core/block_node.dart';
import 'package:canvas_text_editor/core/table_attributes.dart';

class ImageNode extends BlockNode {
  final String imageUrl;
  final double? width;
  final double? height;

  ImageNode({
    required super.nodeId,
    super.parentId,
    required this.imageUrl,
    this.width,
    this.height,
    super.table,
  });

  @override
  BlockKind get kind => BlockKind.image;

  @override
  int get length => 1; // Image nodes typically have a length of 1 for cursor movement

  @override
  Map<String, dynamic> getAttributes() {
    return {
      'imageUrl': imageUrl,
      'width': width,
      'height': height,
    };
  }

  @override
  ImageNode copyWith({
    String? nodeId,
    String? parentId,
    String? imageUrl,
    double? width,
    double? height,
    TableAttributes? table,
  }) {
    return ImageNode(
      nodeId: nodeId ?? this.nodeId,
      parentId: parentId ?? this.parentId,
      imageUrl: imageUrl ?? this.imageUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      table: table ?? this.table,
    );
  }
}
