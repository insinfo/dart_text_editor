// Arquivo: C:\MyDartProjects\canvas_text_editor\test\attributes\inline_attributes_test.dart
import 'package:test/test.dart';
import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/apply_inline_attributes_command.dart';
import 'package:dart_text_editor/core/insert_text_command.dart';
import 'package:dart_text_editor/editor.dart';
import '../mocks/manual_dom_api_mocks.dart';
import '../mocks/mock_text_measurer.dart';
import 'package:dart_text_editor/render/measure_cache.dart';

void main() {
  group('Inline Attributes Tests', () {
    late DocumentModel document;
    late Editor editor;
    late MockCanvasElementApi canvas;

    setUp(() {
      document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'Text with ', InlineAttributes()),
          TextRun(10, 'mixed', InlineAttributes(bold: true)),
          TextRun(15, ' styles', InlineAttributes()),
        ]),
      ]);

      canvas = MockCanvasElementApi();
      final overlay = MockDivElementApi();
      editor = Editor(
        canvas,
        document,
        measureCache: MeasureCache(MockTextMeasurer()),
        overlay: overlay,
      );
    });

    test('Apply bold to collapsed selection updates typing attributes', () {
      // Posicionar cursor no final do texto
      editor.state = editor.state
          .copyWith(selection: Selection.collapsed(Position(0, 22)));

      // Aplicar bold
      editor.execute(ApplyInlineAttributesCommand(bold: true));

      // Verificar se os atributos de digitação foram atualizados
      expect(editor.state.typingAttributes.bold, true);

      // Documento não deve ter sido modificado
      expect(editor.state.document.nodes.length, 1);
      final paragraph = editor.state.document.nodes[0] as ParagraphNode;
      expect(paragraph.runs.length, 3);
    });

    test('Apply multiple attributes to collapsed selection', () {
      editor.state =
          editor.state.copyWith(selection: Selection.collapsed(Position(0, 0)));

      // Aplicar bold e italic
      editor.execute(ApplyInlineAttributesCommand(
        bold: true,
        italic: true,
      ));

      expect(editor.state.typingAttributes.bold, true);
      expect(editor.state.typingAttributes.italic, true);
    });

    test('Toggle attributes off in collapsed selection', () {
      // Primeiro ativar alguns atributos
      editor.state = editor.state.copyWith(
          typingAttributes: InlineAttributes(bold: true, italic: true));

      // Desativar bold
      // CORREÇÃO: Usa o novo construtor para especificar apenas a alteração do 'bold'.
      editor.execute(ApplyInlineAttributesCommand(bold: false));

      expect(editor.state.typingAttributes.bold, false);
      expect(editor.state.typingAttributes.italic, true); // Agora deve passar
    });

    test('New typing uses current attributes', () {
      // Posicionar no fim e ativar bold
      editor.state = editor.state.copyWith(
          selection: Selection.collapsed(Position(0, 22)),
          typingAttributes: InlineAttributes(bold: true));

      // Digitar texto
      editor.execute(InsertTextCommand('new'));

      // Verificar que o novo texto tem bold
      final paragraph = editor.state.document.nodes[0] as ParagraphNode;
      final lastRun = paragraph.runs.last;
      expect(lastRun.attributes.bold, true);
      expect(lastRun.text, 'new');
    });
  });
}