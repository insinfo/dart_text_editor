import 'package:dart_text_editor/core/block_kind.dart';
import 'package:dart_text_editor/core/block_node.dart';
import 'package:dart_text_editor/core/table_row_node.dart';
import 'package:dart_text_editor/core/table_attributes.dart';

class TableNode extends BlockNode {
  final List<TableRowNode> rows;
  final TableAttributes tableAttributes;

  TableNode({
    required super.nodeId,
    super.parentId,
    required this.rows,
    required this.tableAttributes,
  }) : super(table: tableAttributes);

  @override
  BlockKind get kind => BlockKind.table;

  @override
  int get length => rows.fold(0, (prev, row) => prev + row.length);

  @override
  Map<String, dynamic> getAttributes() {
    return tableAttributes.toMap();
  }

  @override
  TableNode copyWith({
    String? nodeId,
    String? parentId,
    List<TableRowNode>? rows,
    TableAttributes? tableAttributes,
  }) {
    return TableNode(
      nodeId: nodeId ?? this.nodeId,
      parentId: parentId ?? this.parentId,
      rows: rows ?? this.rows,
      tableAttributes: tableAttributes ?? this.tableAttributes,
    );
  }
}
