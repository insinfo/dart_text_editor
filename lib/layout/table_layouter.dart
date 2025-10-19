import 'package:canvas_text_editor/core/table_node.dart';
import 'package:canvas_text_editor/layout/page_constraints.dart';
import 'package:canvas_text_editor/layout/table_layout_result.dart';
import 'package:canvas_text_editor/layout/table_row_layout.dart';

class TableLayouter {
  TableLayoutResult layout(TableNode node, PageConstraints constraints) {
    // This is a very basic implementation that gives equal width to all columns.
    final columnCount = node.rows.first.cells.length;
    final columnWidth = constraints.width / columnCount;
    final columnWidths = List.filled(columnCount, columnWidth);

    final rowLayouts = <TableRowLayout>[];
    double totalHeight = 0;
    for (final _ in node.rows) {
      // Assuming a fixed row height for now
      final rowHeight = 50.0;
      rowLayouts.add(TableRowLayout(columnWidths, rowHeight));
      totalHeight += rowHeight;
    }

    return TableLayoutResult(rowLayouts, columnWidths, totalHeight);
  }
}
