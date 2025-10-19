import 'package:dart_text_editor/core/block_kind.dart';
import 'package:dart_text_editor/core/block_node.dart';
import 'package:dart_text_editor/core/table_cell_node.dart';
import 'package:dart_text_editor/core/table_attributes.dart';

class TableRowNode extends BlockNode {
  final List<TableCellNode> cells;

  TableRowNode({
    required super.nodeId,
    super.parentId,
    required this.cells,
    super.table,
  });

  @override
  BlockKind get kind => BlockKind.tableRow;

  @override
  int get length => cells.fold(0, (prev, cell) => prev + cell.length);

  @override
  Map<String, dynamic> getAttributes() {
    return {}; // TableRowNode currently has no specific attributes
  }

  @override
  TableRowNode copyWith({
    String? nodeId,
    String? parentId,
    List<TableCellNode>? cells,
    TableAttributes? table,
  }) {
    return TableRowNode(
      nodeId: nodeId ?? this.nodeId,
      parentId: parentId ?? this.parentId,
      cells: cells ?? this.cells,
      table: table ?? this.table,
    );
  }
}
