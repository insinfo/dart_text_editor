import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/text_run.dart';
import 'package:canvas_text_editor/editor.dart';
import 'package:canvas_text_editor/core/inline_attributes.dart';

import 'package:canvas_text_editor/util/dom_api_web.dart' as dom_api_web;
import 'dart:html' as html; // Importar dart:html com prefixo para evitar conflitos

void main() {
  final htmlCanvas = html.querySelector('#canvas') as html.CanvasElement;
  final canvasElementApi = dom_api_web.createCanvasElement(canvas: htmlCanvas);
  canvasElementApi.width = 800;
  canvasElementApi.height = 600;

  final doc = DocumentModel([
    ParagraphNode([
      TextRun(0, 'Hello, world! This is a simple text editor built with Dart and Canvas. Try typing something.', InlineAttributes()),
      TextRun(0, 'This is a new line with some bold text.', InlineAttributes(bold: true)),
      TextRun(0, ' And some italic text.', InlineAttributes(italic: true)),
      TextRun(0, ' And some underlined text.', InlineAttributes(underline: true)),
      TextRun(0, ' And some strikethrough text.', InlineAttributes(strikethrough: true)),
      TextRun(0, ' And some text with a background color.', InlineAttributes(backgroundColor: 'yellow')), 
    ]),
    ParagraphNode([
      TextRun(0, 'This is another paragraph.', InlineAttributes()),
    ]),
  ]);

  final editor = Editor(canvasElementApi, doc);
  editor.paint();
}