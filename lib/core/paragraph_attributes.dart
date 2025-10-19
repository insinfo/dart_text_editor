import 'package:dart_text_editor/util/web_ui.dart';

class ParagraphAttributes {
  final TextAlign align;
  final double lineSpacing;
  final double indentFirstLine;
  final double spacingBefore;
  final double spacingAfter;

  const ParagraphAttributes({
    this.align = TextAlign.left,
    this.lineSpacing = 1.2,
    this.indentFirstLine = 0.0,
    this.spacingBefore = 0.0,
    this.spacingAfter = 8.0,
  });

  ParagraphAttributes copyWith({
    TextAlign? align,
    double? lineSpacing,
    double? indentFirstLine,
    double? spacingBefore,
    double? spacingAfter,
  }) {
    return ParagraphAttributes(
      align: align ?? this.align,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      indentFirstLine: indentFirstLine ?? this.indentFirstLine,
      spacingBefore: spacingBefore ?? this.spacingBefore,
      spacingAfter: spacingAfter ?? this.spacingAfter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParagraphAttributes &&
          runtimeType == other.runtimeType &&
          align == other.align &&
          lineSpacing == other.lineSpacing &&
          indentFirstLine == other.indentFirstLine &&
          spacingBefore == other.spacingBefore &&
          spacingAfter == other.spacingAfter;

  @override
  int get hashCode =>
      align.hashCode ^
      lineSpacing.hashCode ^
      indentFirstLine.hashCode ^
      spacingBefore.hashCode ^
      spacingAfter.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'align': align.toString().split('.').last,
      'lineSpacing': lineSpacing,
      'indentFirstLine': indentFirstLine,
      'spacingBefore': spacingBefore,
      'spacingAfter': spacingAfter,
    };
  }

  static ParagraphAttributes fromMap(Map<String, dynamic> map) {
    return ParagraphAttributes(
      align: TextAlign.values.firstWhere(
          (e) => e.toString().split('.').last == map['align'],
          orElse: () => TextAlign.left),
      lineSpacing: map['lineSpacing'] as double,
      indentFirstLine: map['indentFirstLine'] as double,
      spacingBefore: map['spacingBefore'] as double,
      spacingAfter: map['spacingAfter'] as double,
    );
  }
}
