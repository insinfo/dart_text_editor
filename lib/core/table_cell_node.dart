import 'package:canvas_text_editor/core/block_kind.dart';
import 'package:canvas_text_editor/core/block_node.dart';
import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/table_attributes.dart';

class TableCellNode extends BlockNode {
  final DocumentModel content;

  TableCellNode({
    required super.nodeId,
    super.parentId,
    required this.content,
    super.table,
  });

  @override
  BlockKind get kind => BlockKind.tableCell;

  @override
  int get length => content.length; // The length of the cell is the length of its content

  @override
  Map<String, dynamic> getAttributes() {
    return {}; // TableCellNode currently has no specific attributes
  }

  @override
  TableCellNode copyWith({
    String? nodeId,
    String? parentId,
    DocumentModel? content,
    TableAttributes? table,
  }) {
    return TableCellNode(
      nodeId: nodeId ?? this.nodeId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      table: table ?? this.table,
    );
  }
}
