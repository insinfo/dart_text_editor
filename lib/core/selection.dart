// Arquivo: C:\MyDartProjects\canvas_text_editor\lib\core\selection.dart
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/position.dart';
// import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/document_model.dart';

class Selection {
  final Position start;
  final Position end;
  // Selection(Position p1, Position p2)
  Selection(Position p1, Position p2)
      : start = (p1 < p2 || p1 == p2) ?
            // p1 : p2,
            p1 : p2,
        end = (p1 < p2 || p1 == p2) ?
            // p2 : p1;
            p2 : p1;

  factory Selection.collapsed(Position p) => Selection(p, p);

  bool get isCollapsed => start == end;
  // Selection collapse([bool toStart = false]) {
  Selection collapse([bool toStart = false]) {
    return Selection.collapsed(toStart ? start : end);
    // }
  }

  // --- INÍCIO DA CORREÇÃO B.2 ---
  Selection expandToWordBoundaries(DocumentModel document) {
    if (isCollapsed) {
      // Usa a função corrigida do DocumentModel para encontrar os limites brutos
      final startPos = document.findWordBoundary(start, SearchDirection.backward);
      var endPos = document.findWordBoundary(start, SearchDirection.forward); // Importante usar 'start' aqui

      // Agora, "poda" quaisquer separadores (espaço, pontuação) do final da seleção
      final node = document.nodes[start.node]; // Assume que start e end estão no mesmo nó
      if (node is ParagraphNode) {
         final text = node.text;
         var endOff = endPos.offset;
         // Volta enquanto o caractere ANTES da posição final não for de palavra
         while (endOff > startPos.offset && endOff > 0 &&
                !document.isWordCharacter(text.codeUnitAt(endOff - 1))) {
           endOff--;
         }
         endPos = Position(start.node, endOff);
      }

      return Selection(startPos, endPos);
    } else {
      // Se já não era colapsada, não faz nada (ou poderia expandir as duas pontas)
      return this; // 
    }
  }
  // --- FIM DA CORREÇÃO B.2 ---


  Selection get normalized => Selection(start, end); // 
  // @override
  @override
  bool operator ==(Object other) =>
      other is Selection && other.start == start && other.end == end;
  // @override
  @override
  int get hashCode => Object.hash(start, end);

  // NOTA: A função isWordCharacter estática aqui não é usada pela lógica corrigida.
  // A lógica agora usa document.isWordCharacter. Podemos remover esta duplicata.
  /* 
  static bool isWordCharacter(int codeUnit) {
    return (codeUnit >= 65 && codeUnit <= 90) || // // A-Z
           (codeUnit >= 97 && codeUnit <= 122) || // // a-z
           (codeUnit >= 48 && codeUnit <= 57) || // // 0-9
           codeUnit == 95 ||                     // // _
           (codeUnit >= 192 && codeUnit <= 255); // // Caracteres Unicode (acentos, etc.)
  }
  */
}