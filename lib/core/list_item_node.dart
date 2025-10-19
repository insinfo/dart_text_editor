import 'package:canvas_text_editor/core/block_kind.dart';
import 'package:canvas_text_editor/core/block_node.dart';
import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/list_attributes.dart';

class ListItemNode extends BlockNode {
  final DocumentModel content;
  final ListAttributes listAttributes;

  ListItemNode({
    required super.nodeId,
    super.parentId,
    required this.content,
    required this.listAttributes,
  });

  @override
  BlockKind get kind => BlockKind.listItem;

  @override
  int get length => content.length; // The length of the list item is the length of its content

  @override
  Map<String, dynamic> getAttributes() {
    return listAttributes.toMap();
  }

  @override
  ListItemNode copyWith({
    String? nodeId,
    String? parentId,
    DocumentModel? content,
    ListAttributes? listAttributes,
  }) {
    return ListItemNode(
      nodeId: nodeId ?? this.nodeId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      listAttributes: listAttributes ?? this.listAttributes,
    );
  }
}
