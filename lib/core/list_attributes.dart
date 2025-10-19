enum ListType {
  ordered,
  unordered,
}

class ListAttributes {
  final ListType type;
  final int level; // Indentation level

  ListAttributes({
    this.type = ListType.unordered,
    this.level = 0,
  });

  ListAttributes copyWith({
    ListType? type,
    int? level,
  }) {
    return ListAttributes(
      type: type ?? this.type,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'level': level,
    };
  }

  static ListAttributes fromMap(Map<String, dynamic> map) {
    return ListAttributes(
      type: ListType.values.firstWhere(
          (e) => e.toString().split('.').last == map['type'],
          orElse: () => ListType.unordered),
      level: map['level'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListAttributes &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          level == other.level;

  @override
  int get hashCode => type.hashCode ^ level.hashCode;
}
