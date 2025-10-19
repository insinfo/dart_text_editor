import 'package:dart_text_editor/core/block_kind.dart';
import 'package:dart_text_editor/core/table_attributes.dart';
import 'package:dart_text_editor/core/node.dart';

abstract class BlockNode extends Node {
  BlockKind get kind;
  final TableAttributes? table;

  BlockNode({required super.nodeId, super.parentId, this.table});

  int get length;
}
