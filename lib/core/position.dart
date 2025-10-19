class Position {
  final int node;    // índice do BlockNode no DocumentModel
  final int offset;  // número de chars dentro do bloco (parágrafo)

  const Position(this.node, this.offset);

  // Add the less than operator
  bool operator <(Position other) {
    if (node != other.node) {
      return node < other.node;
    }
    return offset < other.offset;
  }
  @override
  bool operator ==(Object other) => other is Position && other.node == node && other.offset == offset;
  @override
  int get hashCode => Object.hash(node, offset);
}