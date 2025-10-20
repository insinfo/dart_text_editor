import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:test/test.dart';

void main() {
  group('Debug double click on "Hello"', () {
    late DocumentModel document;
    
    setUp(() {
      // Texto exatamente como na screenshot
      document = DocumentModel([
        ParagraphNode([
          TextRun(0, 'Hello, ', const InlineAttributes()),
          TextRun(7, 'world', const InlineAttributes(bold: true)),
          TextRun(12, '! This is a simple text editor built with Dart and Canvas. Try typing something. ', const InlineAttributes()),
          TextRun(95, 'This is a new line with some ', const InlineAttributes()),
          TextRun(125, 'bold', const InlineAttributes(bold: true)),
          TextRun(129, ' text. ', const InlineAttributes()),
          TextRun(136, 'And some italic text', const InlineAttributes(italic: true)),
          TextRun(156, '. And some ', const InlineAttributes()),
          TextRun(167, 'underlined', const InlineAttributes(underline: true)),
          TextRun(177, ' text. And some ', const InlineAttributes()),
          TextRun(193, 'strikethrough', const InlineAttributes(strikethrough: true)),
          TextRun(206, ' text. And some text with a ', const InlineAttributes()),
          TextRun(235, 'background', const InlineAttributes(backgroundColor: '#FFFF00')),
          TextRun(245, ' color.', const InlineAttributes()),
        ]),
      ]);
    });

    test('Debug: Character positions in text', () {
      final node = document.nodes[0] as ParagraphNode;
      final text = node.text;
      
      print('Full text: "$text"');
      print('Text length: ${text.length}');
      print('\nFirst 20 characters:');
      for (var i = 0; i < 20 && i < text.length; i++) {
        print('  [$i] = "${text[i]}" (code: ${text.codeUnitAt(i)})');
      }
      
      print('\nWord "Hello" should be:');
      print('  Start: 0');
      print('  End: 5');
      print('  Text: "${text.substring(0, 5)}"');
      
      // Verificar se "background" realmente está no texto
      final bgIndex = text.indexOf('background');
      if (bgIndex != -1) {
        print('\nWord "background":');
        print('  Start: $bgIndex');
        print('  End: ${bgIndex + 10}');
        print('  Text: "${text.substring(bgIndex, bgIndex + 10)}"');
      }
    });

    test('Debug: findWordBoundary on position 2 (middle of "Hello")', () {
      final pos = Position(0, 2); // No meio de "Hello"
      
      print('\nTesting position: node=${pos.node}, offset=${pos.offset}');
      
      final node = document.nodes[0] as ParagraphNode;
      final text = node.text;
      print('Character at position 2: "${text[2]}"');
      
      final start = document.findWordBoundary(pos, SearchDirection.backward);
      print('Backward boundary: offset=${start.offset}');
      
      final end = document.findWordBoundary(pos, SearchDirection.forward);
      print('Forward boundary: offset=${end.offset}');
      
      if (start.offset < text.length && end.offset <= text.length) {
        final selectedText = text.substring(start.offset, end.offset);
        print('Selected text: "$selectedText"');
        
        expect(selectedText, 'Hello', 
          reason: 'Should select "Hello" when clicking at position 2');
      }
    });

    test('Debug: expandToWordBoundaries at position 2', () {
      final clickPos = Position(0, 2);
      final selection = Selection.collapsed(clickPos);
      
      print('\nExpanding selection at position 2:');
      final expanded = selection.expandToWordBoundaries(document);
      
      print('Start: node=${expanded.start.node}, offset=${expanded.start.offset}');
      print('End: node=${expanded.end.node}, offset=${expanded.end.offset}');
      
      final node = document.nodes[0] as ParagraphNode;
      final text = node.text;
      final selectedText = text.substring(
        expanded.start.offset, 
        expanded.end.offset
      );
      print('Selected text: "$selectedText"');
      
      expect(selectedText, 'Hello',
        reason: 'Double-click should select "Hello"');
    });

    test('Debug: Test all positions in "Hello"', () {
      print('\nTesting all positions in "Hello":');
      for (var i = 0; i <= 6; i++) {
        final pos = Position(0, i);
        final selection = Selection.collapsed(pos);
        final expanded = selection.expandToWordBoundaries(document);
        
        final node = document.nodes[0] as ParagraphNode;
        final text = node.text;
        final selectedText = text.substring(
          expanded.start.offset,
          expanded.end.offset
        );
        
        print('Position $i: selected "$selectedText" (${expanded.start.offset}-${expanded.end.offset})');
        
        if (i < 5) { // Dentro de "Hello"
          expect(selectedText, 'Hello',
            reason: 'Position $i should select "Hello"');
        } else if (i == 5) { // No espaço após "Hello"
          // Quando está no espaço, expande para palavras adjacentes
          expect(expanded.start.offset, 0, 
            reason: 'Position $i (space) should expand back to start of "Hello"');
          expect(expanded.end.offset, 12, 
            reason: 'Position $i (space) should expand forward to end of "world"');
          expect(selectedText, 'Hello, world',
            reason: 'Should select both words across space');
        } else if (i == 6) { // No início de "world"
          expect(selectedText, 'world',
            reason: 'Position $i should select "world"');
        }
      }
    });

    test('Debug: isWordCharacter for relevant characters', () {
      print('\nTesting isWordCharacter:');
      final testChars = {
        'H': 'H'.codeUnitAt(0),
        'e': 'e'.codeUnitAt(0),
        'l': 'l'.codeUnitAt(0),
        'o': 'o'.codeUnitAt(0),
        ',': ','.codeUnitAt(0),
        ' ': ' '.codeUnitAt(0),
        '!': '!'.codeUnitAt(0),
        '_': '_'.codeUnitAt(0),
        'á': 'á'.codeUnitAt(0),
      };
      
      for (var entry in testChars.entries) {
        final isWord = document.isWordCharacter(entry.value);
        print('  "${entry.key}" (${entry.value}): $isWord');
      }
    });
  });
}