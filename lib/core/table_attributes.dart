
class TableAttributes {
  final int columns;
  final List<double> columnWidths;
  final bool hasHeader;

  TableAttributes({required this.columns, required this.columnWidths, this.hasHeader = false});

  // TODO: Implement TableAttributes properties and methods
  Map<String, dynamic> toMap() {
    return {
      'columns': columns,
      'columnWidths': columnWidths,
      'hasHeader': hasHeader,
    };
  }
}
