// Arquivo: C:\MyDartProjects\canvas_text_editor\lib\core\apply_inline_attributes_command.dart
import 'package:dart_text_editor/core/delta.dart';
import 'package:dart_text_editor/core/editor_command.dart';
import 'package:dart_text_editor/core/editor_state.dart';

import 'package:dart_text_editor/core/transaction.dart';

class ApplyInlineAttributesCommand extends EditorCommand {
  // CORREÇÃO: Os atributos agora são anuláveis para permitir "patches"
  final bool? bold;
  final bool? italic;
  final bool? underline;
  final bool? strikethrough;
  final String? link;
  final double? fontSize;
  final String? fontColor;
  final String? backgroundColor;
  final String? fontFamily;

  ApplyInlineAttributesCommand({
    this.bold,
    this.italic,
    this.underline,
    this.strikethrough,
    this.link,
    this.fontSize,
    this.fontColor,
    this.backgroundColor,
    this.fontFamily,
  });

  // Helper para obter um mapa de atributos não nulos para o Delta
  Map<String, dynamic> _getAttributesMap() {
    final map = <String, dynamic>{};
    if (bold != null) map['bold'] = bold;
    if (italic != null) map['italic'] = italic;
    if (underline != null) map['underline'] = underline;
    if (strikethrough != null) map['strikethrough'] = strikethrough;
    if (link != null) map['link'] = link;
    if (fontSize != null) map['fontSize'] = fontSize;
    if (fontColor != null) map['fontColor'] = fontColor;
    if (backgroundColor != null) map['backgroundColor'] = backgroundColor;
    if (fontFamily != null) map['fontFamily'] = fontFamily;
    return map;
  }

  @override
  Transaction exec(EditorState state) {
    final delta = Delta();
    final selection = state.selection;

    if (selection.isCollapsed) {
      // A lógica para cursor recolhido é tratada diretamente no Editor
      return Transaction.compat(delta, state.selection, state.selection);
    }

    final startOffset = state.document.getOffset(selection.start);
    final endOffset = state.document.getOffset(selection.end);
    final length = endOffset - startOffset;

    if (startOffset > 0) {
      delta.retain(startOffset);
    }

    delta.retain(length, attributes: _getAttributesMap());

    final remainingLength = state.document.length - endOffset;
    if (remainingLength > 0) {
      delta.retain(remainingLength);
    }

    return Transaction.compat(delta, state.selection, state.selection);
  }
}