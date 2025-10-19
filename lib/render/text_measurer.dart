// Arquivo: lib/render/text_measurer.dart (CORRIGIDO)
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/render/metrics.dart';
import 'package:dart_text_editor/render/text_measurer_interface.dart';
import 'package:dart_text_editor/util/dom_api.dart';

class TextMeasurer implements TextMeasurerInterface {
  final CanvasRenderingContext2DApi _ctx;

  TextMeasurer(this._ctx);

  // CORREÇÃO B2: Mede o texto usando os mesmos atributos da pintura.
  static String _fontString(InlineAttributes attributes) {
    final fontSize = attributes.fontSize ?? 16.0;
    final fontFamily = attributes.fontFamily;
    return '${attributes.italic ? 'italic ' : ''}${attributes.bold ? 'bold ' : ''}${fontSize}px $fontFamily';
  }

  @override
  Metrics measure(String text, InlineAttributes attributes) {
    _ctx.font = _fontString(attributes);
    final width = _ctx.measureTextWidth(text);
    final size = attributes.fontSize ?? 16.0;
    // Uma heurística comum para altura da linha.
    return TextMetrics(width: width, height: size * 1.2);
  }
}
