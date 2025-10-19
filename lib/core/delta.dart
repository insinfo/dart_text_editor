import 'package:dart_text_editor/core/delta_op.dart';

class Delta {
  final List<DeltaOp> ops;

  Delta() : ops = [];

  bool get isEmpty => ops.isEmpty;

  int get length {
    return ops.fold<int>(0, (sum, op) {
      if (op.delete != null) {
        return sum + op.delete!;
      } else if (op.retain != null) {
        return sum + op.retain!;
      } else if (op.insert != null) {
        if (op.insert is String) {
          return sum + (op.insert as String).length;
        } else {
          return sum + 1;
        }
      }
      return sum;
    });
  }

  void insert(dynamic data, {Map<String, dynamic>? attributes}) {
    ops.add(DeltaOp.insert(data, attributes: attributes));
  }

  void delete(int length) {
    if (length <= 0) return;
    ops.add(DeltaOp.delete(length));
  }

  void retain(int length, {Map<String, dynamic>? attributes}) {
    if (length <= 0) return;
    ops.add(DeltaOp.retain(length, attributes: attributes));
  }

  void compose(Delta other) {
    ops.addAll(other.ops);
  }
}
