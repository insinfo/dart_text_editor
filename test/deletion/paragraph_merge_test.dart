import 'package:canvas_text_editor/core/block_node.dart';
import 'package:test/test.dart';
import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/text_run.dart';
import 'package:canvas_text_editor/core/inline_attributes.dart';
import 'package:canvas_text_editor/core/selection.dart';
import 'package:canvas_text_editor/core/position.dart';
import 'package:canvas_text_editor/core/delete_command.dart';
import 'package:canvas_text_editor/core/backspace_command.dart';
import 'package:canvas_text_editor/editor.dart';
import '../mocks/manual_dom_api_mocks.dart'; // Importe o arquivo de mocks consolidado
import '../mocks/mock_text_measurer.dart';
import 'package:canvas_text_editor/render/measure_cache.dart';

// Helper para obter o texto de um BlockNode de forma segura
extension BlockNodeText on BlockNode {
  String getText() {
    if (this is ParagraphNode) {
      return (this as ParagraphNode).text;
    }
    return '';
  }
}

void main() {
  group('Delete/Backspace Paragraph Merge Tests', () {
    late DocumentModel document;
    late Editor editor;
    late MockCanvasElementApi canvas;
    late MockWindowApi windowApi;
    late MockDocumentApi documentApi;
    late MockDivElementApi overlayMock;

    setUp(() {
      document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'First paragraph', const InlineAttributes()),
        ]),
        ParagraphNode([
          TextRun(0, 'Second paragraph', const InlineAttributes()),
        ]),
        ParagraphNode([
          TextRun(0, 'Third paragraph', const InlineAttributes()),
        ])
      ]);

      canvas = MockCanvasElementApi();
      windowApi = MockWindowApi();
      overlayMock = MockDivElementApi();
      documentApi = MockDocumentApi();
      
      editor = Editor(
        canvas,
        document,
        measureCache: MeasureCache(MockTextMeasurer()),
        window: windowApi,
        documentApi: documentApi,
        overlay: overlayMock,
      );
    });

    test('Backspace at start of paragraph merges with previous', () {
      // Posicionar o cursor no início do segundo parágrafo
      editor.state = editor.state.copyWith(
        selection: Selection.collapsed(const Position(1, 0))
      );
      
      editor.execute(BackspaceCommand());
      
      expect(editor.state.document.nodes.length, 2);
      expect(
        editor.state.document.nodes[0].getText(),
        'First paragraphSecond paragraph'
      );
    });

    test('Delete at end of paragraph merges with next', () {
      // Posicionar o cursor no final do primeiro parágrafo
      editor.state = editor.state.copyWith(
        selection: Selection.collapsed(const Position(0, 15)) // O tamanho de "First paragraph" é 15
      );
      
      editor.execute(DeleteCommand());
      
      expect(editor.state.document.nodes.length, 2);
      expect(
        editor.state.document.nodes[0].getText(),
        'First paragraphSecond paragraph'
      );
    });

    test('Delete at end of last paragraph does nothing', () {
      final lastParagraph = editor.state.document.nodes.length - 1;
      final lastPosition = editor.state.document.nodes[lastParagraph].length;
      
      editor.state = editor.state.copyWith(
        selection: Selection.collapsed(Position(lastParagraph, lastPosition))
      );
      
      final before = editor.state.document.copyWith(); // Use copyWith() em vez de clone()
      editor.execute(DeleteCommand());
      
      expect(editor.state.document.nodes.length, before.nodes.length);
      expect(
        editor.state.document.nodes.last.getText(),
        before.nodes.last.getText()
      );
    });

    test('Backspace at start of first paragraph does nothing', () {
      editor.state = editor.state.copyWith(
        selection: Selection.collapsed(const Position(0, 0))
      );
      
      final before = editor.state.document.copyWith(); // Use copyWith() em vez de clone()
      editor.execute(BackspaceCommand());
      
      expect(editor.state.document.nodes.length, before.nodes.length);
      expect(
        editor.state.document.nodes.first.getText(),
        before.nodes.first.getText()
      );
    });

    test('Undo restores merged paragraphs correctly', () {
      // Fazer um merge
      editor.state = editor.state.copyWith(
        selection: Selection.collapsed(const Position(1, 0))
      );
      
      editor.execute(BackspaceCommand());
      
      // Verificar que os parágrafos foram unidos
      expect(editor.state.document.nodes.length, 2);
      
      // Desfazer
      editor.undo();
      
      // Verificar que os parágrafos foram restaurados
      expect(editor.state.document.nodes.length, 3);
      expect(
        editor.state.document.nodes[0].getText(),
        'First paragraph'
      );
      expect(
        editor.state.document.nodes[1].getText(),
        'Second paragraph'
      );
    });

    test('Backspace operation can be batched for a single undo', () async {
      // Posicionar no início do segundo parágrafo
      editor.state = editor.state.copyWith(
        selection: Selection.collapsed(const Position(1, 1)) // 1 caractere dentro
      );
      
      // Executar múltiplos backspaces rapidamente
      editor.execute(BackspaceCommand()); // Deleta 1 char
      await Future.delayed(const Duration(milliseconds: 50));
      editor.execute(BackspaceCommand()); // Faz o merge
      
      await Future.delayed(const Duration(milliseconds: 250)); // Espera o batch finalizar
      
      // Deve resultar em um único merge
      expect(editor.state.document.nodes.length, 2);
      expect(editor.state.undoStack.length, 1); // Apenas uma transação de undo
      
      // Um único undo deve restaurar tudo
      editor.undo();
      
      expect(editor.state.document.nodes.length, 3);
      expect(
        editor.state.document.nodes[1].getText(),
        'Second paragraph'
      );
    });
  });
}