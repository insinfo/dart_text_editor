import 'package:dart_text_editor/core/delta.dart';
import 'package:dart_text_editor/core/selection.dart';

class Transaction {
  final Delta delta;
  final Delta inverseDelta;
  final Selection before;
  final Selection after;
  final List<Delta>? subDeltas;
  final List<Delta>? subInverses;

  /// Backwards-compatible constructor. Historical code passed (delta, before, after).
  /// Newer call-sites expect (delta, inverseDelta, before, after). To be flexible,
  /// support both by detecting argument types at call time is not possible in Dart,
  /// so we provide two constructors: the existing one with 4 args and a compatibility
  /// constructor with 3 args where the inverseDelta will be empty.
  Transaction(this.delta, this.inverseDelta, this.before, this.after,
      {this.subDeltas, this.subInverses});

  Transaction.compat(Delta delta, Selection before, Selection after)
      : this(delta, Delta(), before, after);

  static Delta get emptyDelta => Delta();
}
