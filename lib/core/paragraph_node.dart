// Arquivo: lib/core/paragraph_node.dart (CORRIGIDO)
import 'package:canvas_text_editor/core/block_node.dart';
import 'package:canvas_text_editor/core/paragraph_attributes.dart';
import 'package:canvas_text_editor/core/text_run.dart';
import 'package:canvas_text_editor/core/block_kind.dart';

class ParagraphNode extends BlockNode {
  @override
  final BlockKind kind;

  final List<TextRun> runs;
  final ParagraphAttributes attributes;

  ParagraphNode(
    this.runs, {
    String? nodeId,
    super.parentId,
    this.attributes = const ParagraphAttributes(),
    this.kind = BlockKind.paragraph,
  }) : super(
            nodeId: nodeId ?? DateTime.now().microsecondsSinceEpoch.toString());

  String get text => runs.map((run) => run.text).join();

  // CORREÇÃO B1: O comprimento do nó é apenas o comprimento do seu texto.
  // O conceito de separador de parágrafo agora é tratado a nível de bloco, não de caractere.
  @override
  int get length => text.length;

  @override
  Map<String, dynamic> getAttributes() {
    return attributes.toMap();
  }

  @override
  ParagraphNode copyWith({
    String? nodeId,
    String? parentId,
    List<TextRun>? runs,
    ParagraphAttributes? attributes,
    BlockKind? kind,
  }) {
    return ParagraphNode(
      runs ?? this.runs,
      nodeId: nodeId ?? this.nodeId,
      parentId: parentId ?? this.parentId,
      attributes: attributes ?? this.attributes,
      kind: kind ?? this.kind,
    );
  }
}
