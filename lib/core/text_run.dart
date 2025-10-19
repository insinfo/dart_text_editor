import 'package:dart_text_editor/core/inline_attributes.dart';

class TextRun {
  final int textOffset;
  final String text;
  final InlineAttributes attributes;

  TextRun(this.textOffset, this.text, this.attributes);

  TextRun copyWith({
    int? textOffset,
    String? text,
    InlineAttributes? attributes,
  }) {
    return TextRun(
      textOffset ?? this.textOffset,
      text ?? this.text,
      attributes ?? this.attributes,
    );
  }
}
