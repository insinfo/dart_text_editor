import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:test/test.dart';

void main() {
  group('Word boundary tests', () {
    test('findWordBoundary should find "Hello" correctly', () {
      final document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'Hello, world! This is a test.', const InlineAttributes()),
        ]),
      ]);

      // Clicar no meio de "Hello" (posição 2 = 'l')
      final pos = Position(0, 2);
      
      final start = document.findWordBoundary(pos, SearchDirection.backward);
      final end = document.findWordBoundary(pos, SearchDirection.forward);
      
      expect(start.offset, 0, reason: 'Início de "Hello" deve ser 0');
      expect(end.offset, 5, reason: 'Fim de "Hello" deve ser 5');
      
      final node = document.nodes[0] as ParagraphNode;
      final text = node.runs.first.text.substring(start.offset, end.offset);
      expect(text, 'Hello');
    });

    test('findWordBoundary should find "world" correctly', () {
      final document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'Hello, world! This is a test.', const InlineAttributes()),
        ]),
      ]);

      // Clicar no meio de "world" (posição 9 = 'o')
      final pos = Position(0, 9);
      
      final start = document.findWordBoundary(pos, SearchDirection.backward);
      final end = document.findWordBoundary(pos, SearchDirection.forward);
      
      expect(start.offset, 7, reason: 'Início de "world" deve ser 7');
      expect(end.offset, 12, reason: 'Fim de "world" deve ser 12');
      
      final node = document.nodes[0] as ParagraphNode;
      final text = node.runs.first.text.substring(start.offset, end.offset);
      expect(text, 'world');
    });

    test('expandToWordBoundaries should select "Hello" on double click', () {
      final document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'Hello, world!', const InlineAttributes()),
        ]),
      ]);

      // Simular clique duplo no meio de "Hello"
      final clickPos = Position(0, 2);
      final selection = Selection.collapsed(clickPos);
      final expanded = selection.expandToWordBoundaries(document);
      
      expect(expanded.start.offset, 0);
      expect(expanded.end.offset, 5);
      
      final node = document.nodes[0] as ParagraphNode;
      final text = node.runs.first.text.substring(
        expanded.start.offset, 
        expanded.end.offset
      );
      expect(text, 'Hello');
    });

    test('clicking on space expands to surrounding words', () {
      final document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'Hello world', const InlineAttributes()),
        ]),
      ]);

      // Clicar no espaço (posição 5)
      final clickPos = Position(0, 5);
      final selection = Selection.collapsed(clickPos);
      final expanded = selection.expandToWordBoundaries(document);
      
      // Quando clica em espaço, deve expandir para a palavra anterior e próxima
      expect(expanded.start.offset, 0, reason: 'Should go to start of "Hello"');
      expect(expanded.end.offset, 11, reason: 'Should go to end of "world"');
      
      final node = document.nodes[0] as ParagraphNode;
      final text = node.runs.first.text.substring(
        expanded.start.offset,
        expanded.end.offset
      );
      expect(text, 'Hello world');
    });

    test('findWordBoundary at document edges', () {
      final document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'Test', const InlineAttributes()),
        ]),
      ]);

      // No início
      var pos = Position(0, 0);
      var start = document.findWordBoundary(pos, SearchDirection.backward);
      expect(start.offset, 0);

      // No final
      pos = Position(0, 4);
      var end = document.findWordBoundary(pos, SearchDirection.forward);
      expect(end.offset, 4);
    });
    
    test('findWordBoundary with multiple spaces', () {
      final document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'Hello   world', const InlineAttributes()),
        ]),
      ]);

      // Clicar no segundo espaço (posição 6)
      final pos = Position(0, 6);
      
      final start = document.findWordBoundary(pos, SearchDirection.backward);
      final end = document.findWordBoundary(pos, SearchDirection.forward);
      
      // Quando está em espaço, pula os espaços e vai para palavra adjacente
      expect(start.offset, 0, reason: 'Should go to start of "Hello"');
      expect(end.offset, 13, reason: 'Should go to end of "world"');
      
      // Teste adicional: verificar o texto selecionado
      final node = document.nodes[0] as ParagraphNode;
      final selectedText = node.text.substring(start.offset, end.offset);
      expect(selectedText, 'Hello   world');
    });

    test('word boundary with punctuation', () {
      final document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'Hello, world!', const InlineAttributes()),
        ]),
      ]);

      // Clicar na vírgula (posição 5)
      final pos = Position(0, 5);
      
      final start = document.findWordBoundary(pos, SearchDirection.backward);
      final end = document.findWordBoundary(pos, SearchDirection.forward);
      
      // Vírgula é tratada como separador
      expect(start.offset, 0, reason: 'Should go back to "Hello"');
      expect(end.offset, 12, reason: 'Should go forward to end of "world"');
      
      final node = document.nodes[0] as ParagraphNode;
      final text = node.text.substring(start.offset, end.offset);
      expect(text, 'Hello, world');
    });

    test('word boundary with underscores', () {
      final document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'hello_world test', const InlineAttributes()),
        ]),
      ]);

      // Clicar no underscore (posição 5)
      final pos = Position(0, 5);
      
      final start = document.findWordBoundary(pos, SearchDirection.backward);
      final end = document.findWordBoundary(pos, SearchDirection.forward);
      
      // Underscore é parte da palavra
      expect(start.offset, 0, reason: 'Should include underscore in word');
      expect(end.offset, 11, reason: 'Should treat hello_world as one word');
      
      final node = document.nodes[0] as ParagraphNode;
      final text = node.text.substring(start.offset, end.offset);
      expect(text, 'hello_world');
    });
  });
}