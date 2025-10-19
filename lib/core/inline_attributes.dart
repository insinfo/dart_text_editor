// Arquivo: lib/core/inline_attributes.dart (COMPLETO E CORRIGIDO)
class InlineAttributes {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final String? link;
  final double? fontSize;
  final String? fontColor;
  final String? backgroundColor;
  final String fontFamily;

  const InlineAttributes({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.link,
    this.fontSize,
    this.fontColor,
    this.backgroundColor,
    this.fontFamily = 'Times New Roman',
  });

  InlineAttributes copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    String? link,
    double? fontSize,
    String? fontColor,
    String? backgroundColor,
    String? fontFamily,
  }) {
    return InlineAttributes(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      link: link ?? this.link,
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  InlineAttributes merge(InlineAttributes other) {
    // CORREÇÃO: A lógica de merge foi alterada para funcionar como um "patch"
    // ou "toggle". Um atributo de `other` só sobrescreve o atributo de `this`
    // se for diferente do valor padrão. Isso evita que, ao se passar
    // `InlineAttributes(bold: false)`, o atributo `italic` (que por padrão é
    // `false` em `other`) sobrescreva um valor `true` em `this`.
    const defaults = InlineAttributes();
    return copyWith(
      bold: other.bold, // Atributos booleanos são sempre aplicados
      italic: other.italic,
      underline: other.underline,
      strikethrough: other.strikethrough,
      // Atributos que podem ser nulos são aplicados se forem diferentes do padrão
      link: other.link != defaults.link ? other.link : link,
      fontSize: other.fontSize != defaults.fontSize ? other.fontSize : fontSize,
      fontColor:
          other.fontColor != defaults.fontColor ? other.fontColor : fontColor,
      backgroundColor: other.backgroundColor != defaults.backgroundColor
          ? other.backgroundColor
          : backgroundColor,
      fontFamily: other.fontFamily != defaults.fontFamily
          ? other.fontFamily
          : fontFamily,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InlineAttributes &&
          runtimeType == other.runtimeType &&
          bold == other.bold &&
          italic == other.italic &&
          underline == other.underline &&
          strikethrough == other.strikethrough &&
          link == other.link &&
          fontSize == other.fontSize &&
          fontColor == other.fontColor &&
          backgroundColor == other.backgroundColor &&
          fontFamily == other.fontFamily;

  @override
  int get hashCode =>
      bold.hashCode ^
      italic.hashCode ^
      underline.hashCode ^
      strikethrough.hashCode ^
      link.hashCode ^
      fontSize.hashCode ^
      fontColor.hashCode ^
      backgroundColor.hashCode ^
      fontFamily.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'bold': bold,
      'italic': italic,
      'underline': underline,
      'strikethrough': strikethrough,
      'link': link,
      'fontSize': fontSize,
      'fontColor': fontColor,
      'backgroundColor': backgroundColor,
      'fontFamily': fontFamily,
    };
  }

  static InlineAttributes fromMap(Map<String, dynamic> map) {
    return InlineAttributes(
      bold: map['bold'] as bool? ?? false,
      italic: map['italic'] as bool? ?? false,
      underline: map['underline'] as bool? ?? false,
      strikethrough: map['strikethrough'] as bool? ?? false,
      link: map['link'] as String?,
      fontSize: map['fontSize'] as double?,
      fontColor: map['fontColor'] as String?,
      backgroundColor: map['backgroundColor'] as String?,
      fontFamily: map['fontFamily'] as String? ?? 'Times New Roman',
    );
  }
}
