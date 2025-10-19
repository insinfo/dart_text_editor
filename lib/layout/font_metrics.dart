class FontMetrics {
  final double fontSize;

  FontMetrics(this.fontSize);

  double get lineHeight => fontSize * 1.2;
}