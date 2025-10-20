// Arquivo: lib/util/web_ui.dart

class Color {
  final int value;

  const Color(this.value);

  int get alpha => (value >> 24) & 0xFF;
  int get red => (value >> 16) & 0xFF;
  int get green => (value >> 8) & 0xFF;
  int get blue => value & 0xFF;

  String toRgbaString() {
    // Garante que alpha/255.0 tenha pelo menos uma casa decimal
    return 'rgba($red, $green, $blue, ${(alpha / 255.0).toStringAsFixed(3)})';
  }

  // --- MÉTODO ADICIONADO ---
  /// Retorna uma nova cor com o componente alfa substituído.
  /// Alpha é um int de 0 a 255.
  Color withAlpha(int alpha) {
    // Garante que o alpha esteja no range correto e remove o alpha antigo antes de adicionar o novo
    return Color((value & 0x00FFFFFF) | ((alpha.clamp(0, 255)) << 24));
  }
  // --- FIM DA ADIÇÃO ---

}

enum TextAlign {
  left,
  right,
  center,
  justify,
}