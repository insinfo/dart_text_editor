class Position {
  final int node; // índice do BlockNode no DocumentModel
  final int offset; // número de chars dentro do bloco (parágrafo)

  const Position(this.node, this.offset);

  bool operator <(Position other) =>
      node < other.node || (node == other.node && offset < other.offset);
  bool operator <=(Position other) => this < other || this == other;

  @override
  String toString() => 'Pos(node: $node, offset: $offset)';

  @override
  bool operator ==(Object other) =>
      other is Position && other.node == node && other.offset == offset;
  @override
  int get hashCode => Object.hash(node, offset);
}
