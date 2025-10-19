import 'package:dart_text_editor/core/block_kind.dart';
import 'package:dart_text_editor/core/block_node.dart';
import 'package:dart_text_editor/core/list_item_node.dart';
import 'package:dart_text_editor/core/list_attributes.dart';

class ListNode extends BlockNode {
  final List<ListItemNode> items;
  final ListAttributes listAttributes;

  ListNode({
    required super.nodeId,
    super.parentId,
    required this.items,
    required this.listAttributes,
  });

  @override
  BlockKind get kind => BlockKind.list;

  @override
  int get length => items.fold(0, (prev, item) => prev + item.length);

  @override
  Map<String, dynamic> getAttributes() {
    return listAttributes.toMap();
  }

  @override
  ListNode copyWith({
    String? nodeId,
    String? parentId,
    List<ListItemNode>? items,
    ListAttributes? listAttributes,
  }) {
    return ListNode(
      nodeId: nodeId ?? this.nodeId,
      parentId: parentId ?? this.parentId,
      items: items ?? this.items,
      listAttributes: listAttributes ?? this.listAttributes,
    );
  }
}
