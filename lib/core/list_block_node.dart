import 'package:canvas_text_editor/core/block_kind.dart';
import 'package:canvas_text_editor/core/block_node.dart';

class ListBlockNode extends BlockNode {
  final List<BlockNode> items;

  ListBlockNode({List<BlockNode>? items, String? nodeId, super.parentId})
      : items = items ?? [],
        super(nodeId: nodeId ?? DateTime.now().microsecondsSinceEpoch.toString());

  @override
  BlockKind get kind => BlockKind.list;

  @override
  int get length => items.fold(0, (prev, item) => prev + item.length);

  @override
  Map<String, dynamic> getAttributes() => {};

  @override
  ListBlockNode copyWith({String? nodeId, String? parentId}) {
    return ListBlockNode(items: items, nodeId: nodeId ?? this.nodeId, parentId: parentId ?? this.parentId);
  }
}