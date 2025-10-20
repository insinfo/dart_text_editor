// Arquivo: lib/services/clipboard_service.dart
import 'package:dart_text_editor/core/editor_state.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/util/dom_api.dart';

/// Um serviço para encapsular a lógica de interação com a área de transferência.
class ClipboardService {
  final WindowApi _window;
  final DocumentApi _document;

  ClipboardService({
    required WindowApi window,
    required DocumentApi document,
  })  : _window = window,
        _document = document;

  /// Copia o texto selecionado do estado do editor para a área de transferência.
  Future<void> copy(EditorState state) async {
    if (state.selection.isCollapsed) return;

    final textToCopy = _extractTextFromSelection(state);
    if (textToCopy.isEmpty) return;

    try {
      // 1. Tenta a API moderna, que é mais segura e preferível.
      await _window.navigator.clipboard.writeText(textToCopy);
    } catch (e) {
      // 2. Se a API moderna falhar, usa o fallback com execCommand.
      _legacyCopy(textToCopy);
    }
  }

  /// Cola o texto da área de transferência. Retorna o texto colado ou null.
  Future<String?> paste() async {
    try {
      final text = await _window.navigator.clipboard.readText();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    } catch (e) {
      print("A API de colagem moderna não está disponível ou foi negada.");
    }
    return null;
  }
  
  String _extractTextFromSelection(EditorState state) {
    final selection = state.selection.normalized;
    final doc = state.document;
    var text = '';

    for (int i = selection.start.node; i <= selection.end.node; i++) {
      final node = doc.nodes[i];
      if (node is ParagraphNode) {
        final start = (i == selection.start.node) ? selection.start.offset : 0;
        final end =
            (i == selection.end.node) ? selection.end.offset : node.text.length;

        if (start < end) {
          text += node.text.substring(start, end);
        }

        if (i < selection.end.node) {
          text += '\n';
        }
      }
    }
    return text;
  }

  // --- INÍCIO DA CORREÇÃO ---
  /// Usa a técnica de criar uma textarea temporária e fora da tela para
  /// executar o comando de cópia. É muito mais seguro do que manipular a div overlay.
  bool _legacyCopy(String text) {
    final textarea = _document.createElement('textarea') as TextAreaElementApi;
    try {
      // Posiciona o elemento fora da tela
      textarea.style.position = 'absolute';
      textarea.style.left = '-9999px';
      textarea.style.top = '0';
      
      _document.body!.append(textarea);
      
      textarea.value = text;
      textarea.select();

      return _document.execCommand('copy');
    } catch (e) {
      print("Falha ao usar o método de cópia legado: $e");
      return false;
    } finally {
      // Garante que o elemento seja removido do DOM
      textarea.remove();
    }
  }
  // --- FIM DA CORREÇÃO ---
}