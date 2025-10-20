import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/editor.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/util/dom_api_web.dart' as dom_api_web;

import 'dart:js_util' as js_util;
import 'package:web/web.dart' as html;

void main() {
  final htmlCanvas = html.HTMLCanvasElement()
    ..width = 800
    ..height = 600
    ..style.border = '1px solid black'
    ..style.margin = '0'
    ..style.padding = '0';
  html.document.body?.append(htmlCanvas);

  final canvasElementApi = dom_api_web.createCanvasElement(canvas: htmlCanvas)
    ..width = 800
    ..height = 600;

  final doc = DocumentModel([
    ParagraphNode([
      TextRun(0,
          'Hello, world! This is a simple text editor built with Dart and Canvas. Try typing something.',
          const InlineAttributes()),
      TextRun(95,
          ' This is a new line with some bold text.',
          const InlineAttributes(bold: true)),
      TextRun(129,
          ' And some italic text.',
          const InlineAttributes(italic: true)),
      TextRun(156,
          ' And some underlined text.',
          const InlineAttributes(underline: true)),
      TextRun(177,
          ' And some strikethrough text.',
          const InlineAttributes(strikethrough: true)),
      TextRun(206,
          ' And some text with a background color.',
          const InlineAttributes(backgroundColor: '#FFFF00')),
    ]),
    ParagraphNode([
      TextRun(0, 'This is another paragraph.', const InlineAttributes()),
    ]),
  ]);

  final editor = Editor(canvasElementApi, doc);
  editor.paint();

  // === Funções utilitárias para inspeção/teste - com allowInterop ===
  String nodeText(int i) {
    final node = doc.nodes[i] as ParagraphNode;
    return node.runs.map((r) => r.text).join();
  }

  Map<String, dynamic> snapshot() {
    final sel = editor.state.selection;
    return {
      'document': {
        'nodes': List.generate(doc.nodes.length, (i) => {'text': nodeText(i)}),
      },
      'selection': {
        'startNode': sel.start.node,
        'startOffset': sel.start.offset,
        'endNode': sel.end.node,
        'endOffset': sel.end.offset,
        'isCollapsed': sel.isCollapsed,
      }
    };
  }

  String getSelectedText() {
    final sel = editor.state.selection;
    if (sel.isCollapsed) return '';
    
    final node = doc.nodes[sel.start.node] as ParagraphNode;
    final fullText = node.runs.map((r) => r.text).join();
    
    // Ajustar os offsets para respeitar os limites do texto combinado
    final startOffset = sel.start.offset.clamp(0, fullText.length);
    final endOffset = sel.end.offset.clamp(0, fullText.length);
    
    if (startOffset >= endOffset) return '';
    
    final selectedText = fullText.substring(startOffset, endOffset);
    print('Debug: Selected text - Node: ${sel.start.node}, Start: $startOffset, End: $endOffset, Text: "$selectedText"');
    return selectedText;
  }

  js_util.setProperty(html.window, '__getSnapshot', js_util.allowInterop(snapshot));
  js_util.setProperty(html.window, '__getDocText',
      js_util.allowInterop((int node) => nodeText(node)));
  js_util.setProperty(html.window, '__getSelectedText', js_util.allowInterop(getSelectedText));
  js_util.setProperty(
      html.window,
      '__selectRange',
      js_util.allowInterop((int node, int start, int end) {
        final posStart = Position(node, start);
        final posEnd = Position(node, end);
        editor.state = editor.state.copyWith(selection: Selection(posStart, posEnd));
        editor.paint();
        print('Debug: Applied selection - Node: $node, Start: $start, End: $end');
      }));

  // Adicionar listener para depuração de cliques
  canvasElementApi.onDoubleClick.listen((event) {
    final rect = canvasElementApi.getBoundingClientRect();
    final x = event.client.x - rect.left;
    final y = event.client.y - rect.top;
    
    final position = editor.paginator.getPositionFromScreen(x.toDouble(), y.toDouble());
    if (position != null) {
      final clickPos = Position(position.node, position.offset);
      final newSelection = Selection.collapsed(clickPos).expandToWordBoundaries(doc);
      editor.state = editor.state.copyWith(selection: newSelection);
      editor.paint();
      print('Debug: Double click at ($x, $y) - Position: $position, Expanded to: $newSelection');
    }
  });
}