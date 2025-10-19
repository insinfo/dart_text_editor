class DeltaOp {
  final dynamic insert;
  final int? delete;
  final int? retain;
  final Map<String, dynamic>? attributes;

  DeltaOp.insert(this.insert, {this.attributes}) : delete = null, retain = null;
  DeltaOp.delete(this.delete) : insert = null, retain = null, attributes = null;
  DeltaOp.retain(this.retain, {this.attributes}) : insert = null, delete = null;

  @override
  String toString() {
    if (insert != null) return 'insert(${insert.toString()})';
    if (delete != null) return 'delete($delete)';
    if (retain != null) return 'retain($retain)';
    return 'op()';
  }
}
