class Color {
  final int value;

  const Color(this.value);

  int get alpha => (value >> 24) & 0xFF;
  int get red => (value >> 16) & 0xFF;
  int get green => (value >> 8) & 0xFF;
  int get blue => value & 0xFF;

  String toRgbaString() {
    return 'rgba($red, $green, $blue, ${alpha / 255.0})';
  }
}

enum TextAlign {
  left,
  right,
  center,
  justify,
}
