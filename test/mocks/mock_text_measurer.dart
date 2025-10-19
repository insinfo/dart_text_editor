// Arquivo: test/mocks/mock_text_measurer.dart (COMPLETO E CORRIGIDO)
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/render/metrics.dart';
import 'package:dart_text_editor/render/text_measurer_interface.dart';

class MockTextMeasurer implements TextMeasurerInterface {
  // CORREÇÃO: Adicionado o campo e o construtor para permitir largura customizada
  final double charWidth;

  MockTextMeasurer({this.charWidth = 8.0});

  @override
  Metrics measure(String text, InlineAttributes attributes) {
    // CORREÇÃO: Usa o 'charWidth' do campo em vez de um valor fixo
    return MockMetrics(
        width: text.length * charWidth, height: attributes.fontSize ?? 16.0);
  }
}

class MockMetrics implements Metrics {
  @override
  final double width;
  @override
  final double height;

  MockMetrics({required this.width, this.height = 16.0});
}
