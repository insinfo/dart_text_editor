// Arquivo: lib/core/document_model.dart (COMPLETO E CORRIGIDO)
// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:canvas_text_editor/core/block_node.dart';
import 'package:canvas_text_editor/core/delta.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/position.dart';
import 'package:canvas_text_editor/core/inline_attributes.dart';
import 'package:canvas_text_editor/core/text_run.dart';

enum SearchDirection {
  forward,
  backward,
}

class DocumentModel {
  final List<BlockNode> nodes;

  DocumentModel(this.nodes);

  DocumentModel copyWith({List<BlockNode>? nodes}) {
    return DocumentModel(nodes ?? List.from(this.nodes));
  }

  int _sepAfterNode(int i) {
    final isParagraph = nodes[i] is ParagraphNode;
    final hasNext = i < nodes.length - 1;
    return (isParagraph && hasNext) ? 1 : 0;
  }

  int get length => nodes.asMap().entries.fold(0, (sum, e) {
    final i = e.key;
    final node = e.value;
    final sep = (node is ParagraphNode && i < nodes.length - 1) ? 1 : 0;
    return sum + node.length + sep;
  });

  // CORREÇÃO B1: Ajustado para não contar o '\n' implícito no final de cada parágrafo de forma inconsistente.
  // O separador de parágrafo é conceitual, não um caractere extra no offset.
  int getOffset(Position position) {
    var offset = 0;
    for (var i = 0; i < position.node; i++) {
      offset += nodes[i].length + _sepAfterNode(i);
    }
    return offset + position.offset;
  }

  Position positionFromOffset(int offset) {
    var current = 0;
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final span = node.length + _sepAfterNode(i);
      if (offset <= current + span) {
        final offInNode = (offset - current).clamp(0, node.length);
        return Position(i, offInNode);
      }
      current += span;
    }
    if (nodes.isEmpty) return const Position(0, 0);
    final last = nodes.last;
    return Position(nodes.length - 1, last.length);
  }

  ({DocumentModel document, Delta inverse, Position? newCaret}) apply(
      Delta delta,
      {Position? beforeCaret}) {
    final newNodes = List<BlockNode>.from(nodes);
  final inverse = Delta();
  var currentOffset = 0;
  var inverseCursor = 0; // Tracks how much of the original document the inverse has retained
    Position? calculatedNewCaret = beforeCaret;

    for (final op in delta.ops) {
      if (op.retain != null) {
        currentOffset += op.retain!;
      } else if (op.insert != null) {
        final insertResult =
            _applyInsert(newNodes, currentOffset, op.insert!, op.attributes);
        if (insertResult != null) {
          calculatedNewCaret = insertResult;
          final insertedLength =
              op.insert is String ? (op.insert as String).length : 1;
          final retainLen = currentOffset - inverseCursor;
          if (retainLen > 0) {
            inverse.retain(retainLen);
            inverseCursor += retainLen;
          }
          inverse.delete(insertedLength);
          // inverseCursor does not change on delete (it refers to original doc position)
          currentOffset += insertedLength;
        }
      } else if (op.delete != null) {
        final length = op.delete!;
        final deletedDelta =
            _getDeletedContentAsDelta(newNodes, currentOffset, length);
        final retainLen = currentOffset - inverseCursor;
        if (retainLen > 0) {
          inverse.retain(retainLen);
          inverseCursor += retainLen;
        }
        inverse.compose(deletedDelta);
        // After composing deletedDelta (which is an insert into inverse),
        // advance inverseCursor by the length of inserted content
        inverseCursor += deletedDelta.length;

        final deletedCaret = _applyDelete(newNodes, currentOffset, length);
        if (deletedCaret != null) {
          calculatedNewCaret = deletedCaret;
        }
      }
    }

    return (
      document: DocumentModel(newNodes),
      inverse: inverse,
      newCaret: calculatedNewCaret
    );
  }

  Position? _applyInsert(List<BlockNode> nodes, int offset, dynamic data,
      Map<String, dynamic>? attributes) {
    if (data is! String) {
      // TODO: Handle embed insertion
      return null;
    }

    final location = _findLocation(nodes, offset);
    if (location == null) {
      // Inserindo no final de um documento não vazio
      if (nodes.isNotEmpty && offset > 0) {
        final lastNode = nodes.last;
        if (lastNode is ParagraphNode) {
          final newRuns = List<TextRun>.from(lastNode.runs)
            ..add(TextRun(lastNode.text.length, data,
                InlineAttributes.fromMap(attributes ?? {})));
          nodes[nodes.length - 1] =
              lastNode.copyWith(runs: _mergeRuns(newRuns));
          return Position(nodes.length - 1, lastNode.length + data.length);
        }
      }
      // Documento vazio ou inserção no início
      nodes.add(ParagraphNode(
          [TextRun(0, data, InlineAttributes.fromMap(attributes ?? {}))]));
      return Position(0, data.length);
    }

    final node = nodes[location.nodeIndex];
    if (node is! ParagraphNode) return null;

    if (data == '\n') {
      final runs = List<TextRun>.from(node.runs);
      final (runIndex, charInRunIndex) =
          _findRunIndexForOffset(runs, location.offsetInNode);
      final targetRun = runs[runIndex];

      final beforeText = targetRun.text.substring(0, charInRunIndex);
      final afterText = targetRun.text.substring(charInRunIndex);

      final beforeRuns = <TextRun>[...runs.sublist(0, runIndex)];
      if (beforeText.isNotEmpty) {
        beforeRuns.add(TextRun(0, beforeText, targetRun.attributes));
      }

      final afterRuns = <TextRun>[];
      if (afterText.isNotEmpty) {
        afterRuns.add(TextRun(0, afterText, targetRun.attributes));
      }
      afterRuns.addAll(runs.sublist(runIndex + 1));

      nodes[location.nodeIndex] = node.copyWith(runs: _mergeRuns(beforeRuns));
      final newNode = ParagraphNode(_mergeRuns(afterRuns),
          nodeId: DateTime.now().microsecondsSinceEpoch.toString(),
          attributes: node.attributes);
      nodes.insert(location.nodeIndex + 1, newNode);

      return Position(location.nodeIndex + 1, 0);
    } else {
      final (runIndex, charInRunIndex) =
          _findRunIndexForOffset(node.runs, location.offsetInNode);
      final newRuns = List<TextRun>.from(node.runs);
      final insertAttributes = InlineAttributes.fromMap(attributes ?? {});

      if (runIndex >= newRuns.length) {
        newRuns.add(TextRun(0, data, insertAttributes));
      } else {
        final targetRun = newRuns[runIndex];
        final beforeText = targetRun.text.substring(0, charInRunIndex);
        final afterText = targetRun.text.substring(charInRunIndex);

        final newRunForInsertion = TextRun(0, data, insertAttributes);
        final runBefore = TextRun(0, beforeText, targetRun.attributes);
        final runAfter = TextRun(0, afterText, targetRun.attributes);

        newRuns.removeAt(runIndex);
        newRuns.insertAll(
            runIndex,
            [runBefore, newRunForInsertion, runAfter]
                .where((r) => r.text.isNotEmpty));
      }

      nodes[location.nodeIndex] = node.copyWith(runs: _mergeRuns(newRuns));
      return Position(location.nodeIndex, location.offsetInNode + data.length);
    }
  }

  Position? _applyDelete(List<BlockNode> nodes, int offset, int length) {
    if (length <= 0) return positionFromOffset(offset);

    final startLoc = _findLocation(nodes, offset);
    final endLoc = _findLocation(nodes, offset + length);

    if (startLoc == null) return null; // Não deveria acontecer

    final endNodeIndex = endLoc?.nodeIndex ?? nodes.length - 1;
    final endOffsetInNode = endLoc?.offsetInNode ?? nodes.last.length;

    // Caso 1: Deleção dentro de um único nó
    if (startLoc.nodeIndex == endNodeIndex) {
      final node = nodes[startLoc.nodeIndex];
      if (node is ParagraphNode) {
        final newRuns = <TextRun>[];
        var currentOffset = 0;
        for (final run in node.runs) {
          final runEndOffset = currentOffset + run.text.length;
          if (runEndOffset <= startLoc.offsetInNode ||
              currentOffset >= endOffsetInNode) {
            newRuns.add(run);
          } else {
            final startInRun = startLoc.offsetInNode > currentOffset
                ? startLoc.offsetInNode - currentOffset
                : 0;
            final endInRun = endOffsetInNode < runEndOffset
                ? endOffsetInNode - currentOffset
                : run.text.length;

            final before = run.text.substring(0, startInRun);
            final after = run.text.substring(endInRun);

            if (before.isNotEmpty)
              newRuns.add(TextRun(0, before, run.attributes));
            if (after.isNotEmpty)
              newRuns.add(TextRun(0, after, run.attributes));
          }
          currentOffset = runEndOffset;
        }
        nodes[startLoc.nodeIndex] = node.copyWith(runs: _mergeRuns(newRuns));
      } else {
        // Deleção de nó de embed
        nodes.removeAt(startLoc.nodeIndex);
      }
      return Position(startLoc.nodeIndex, startLoc.offsetInNode);
    }

    // Caso 2: Deleção abrange múltiplos nós
    final startNode = nodes[startLoc.nodeIndex];
    final endNode = nodes[endNodeIndex];

    // Tratar o nó inicial
    if (startNode is ParagraphNode) {
      final textBefore = startNode.text.substring(0, startLoc.offsetInNode);
      final newRuns = [
        TextRun(0, textBefore,
            startNode.runs.firstOrNull?.attributes ?? const InlineAttributes())
      ];
      nodes[startLoc.nodeIndex] = startNode.copyWith(runs: newRuns);
    }

    // Tratar o nó final
    if (endNode is ParagraphNode) {
      final textAfter = endNode.text.substring(endOffsetInNode);
      if (startNode is ParagraphNode) {
        // Merge de parágrafos
        final mergedRuns = List<TextRun>.from(
            (nodes[startLoc.nodeIndex] as ParagraphNode).runs);
        if (textAfter.isNotEmpty) {
          mergedRuns.add(TextRun(0, textAfter,
              endNode.runs.lastOrNull?.attributes ?? const InlineAttributes()));
        }
        nodes[startLoc.nodeIndex] =
            startNode.copyWith(runs: _mergeRuns(mergedRuns));
      } else {
        // Apenas trunca o nó final
        final newRuns = [
          TextRun(0, textAfter,
              endNode.runs.lastOrNull?.attributes ?? const InlineAttributes())
        ];
        nodes[endNodeIndex] = endNode.copyWith(runs: newRuns);
      }
    }

    // Remover os nós no meio
    final firstNodeToRemove = startLoc.nodeIndex + 1;
    final lastNodeToRemove = endLoc == null ? nodes.length : endNodeIndex;
    if (firstNodeToRemove < lastNodeToRemove) {
      nodes.removeRange(firstNodeToRemove, lastNodeToRemove);
    }
    if (startNode is ParagraphNode && endNode is ParagraphNode) {
      nodes.removeAt(startLoc.nodeIndex + 1);
    }

    return Position(startLoc.nodeIndex, startLoc.offsetInNode);
  }

  _NodeLocation? _findLocation(List<BlockNode> nodes, int docOffset) {
    var current = 0;
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final span = node.length + ((node is ParagraphNode && i < nodes.length - 1) ? 1 : 0);
      final end = current + node.length;
      if (docOffset >= current && docOffset <= end) {
        return _NodeLocation(i, docOffset - current);
      }
      current += span;
    }
    return null;
  }

  (int, int) _findRunIndexForOffset(List<TextRun> runs, int offsetInNode) {
    if (runs.isEmpty) return (0, 0);
    var accumulated = 0;
    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      if (offsetInNode >= accumulated &&
          offsetInNode <= accumulated + run.text.length) {
        return (i, offsetInNode - accumulated);
      }
      accumulated += run.text.length;
    }
    return (runs.length, 0); // Inserir após o último run
  }

  List<TextRun> _mergeRuns(List<TextRun> runs) {
    if (runs.length < 2) return runs;

    final merged = <TextRun>[];
    if (runs.isEmpty) return merged;

    var currentRun = runs.first;

    for (var i = 1; i < runs.length; i++) {
      final nextRun = runs[i];
      if (currentRun.attributes == nextRun.attributes) {
        currentRun =
            TextRun(0, currentRun.text + nextRun.text, currentRun.attributes);
      } else {
        merged.add(currentRun);
        currentRun = nextRun;
      }
    }
    merged.add(currentRun);

    final finalRuns = <TextRun>[];
    var offset = 0;
    for (final run in merged.where((r) => r.text.isNotEmpty)) {
      finalRuns.add(TextRun(offset, run.text, run.attributes));
      offset += run.text.length;
    }

    return finalRuns;
  }

  Delta _getDeletedContentAsDelta(
      List<BlockNode> nodes, int offset, int length) {
    final deletedDelta = Delta();
    // Esta é uma implementação simplificada. Uma implementação robusta
    // precisaria reconstruir o texto e os atributos exatos que foram removidos.
    final startPos = positionFromOffset(offset);
    final endPos = positionFromOffset(offset + length);

    if (startPos.node == endPos.node) {
      final node = nodes[startPos.node];
      if (node is ParagraphNode) {
        // Clamp offsets to valid range to avoid RangeError (defensive).
        final startOffset = startPos.offset.clamp(0, node.text.length);
        final endOffset = endPos.offset.clamp(0, node.text.length);
        if (startOffset >= endOffset) {
          // Nothing deleted inside this node
        } else {
          final text = node.text.substring(startOffset, endOffset);
          // Simplificação: pega os atributos do primeiro run
          final attrs = node.runs.firstWhere((run) {
            final runStart = node.runs
                .takeWhile((r) => r != run)
                .fold<int>(0, (sum, r) => sum + r.text.length);
            return startOffset < runStart + run.text.length;
          }, orElse: () => node.runs.first).attributes;
          deletedDelta.insert(text, attributes: attrs.toMap());
        }
      } else {
        deletedDelta.insert({'embed': node.kind.toString()}, attributes: {});
      }
    } else {
      // Deleção entre parágrafos insere um newline
      deletedDelta.insert('\n');
    }

    return deletedDelta;
  }

  Position findWordBoundary(Position startPosition, SearchDirection direction) {
    final nodeIndex = startPosition.node;
    final offsetInNode = startPosition.offset;

    if (nodeIndex < 0 || nodeIndex >= nodes.length) {
      return startPosition;
    }

    final node = nodes[nodeIndex];
    if (node is! ParagraphNode) {
      return startPosition;
    }

    final text = node.text;
    if (text.isEmpty) {
      return Position(nodeIndex, 0);
    }

    int newOffset = offsetInNode;

    if (direction == SearchDirection.forward) {
      if (newOffset >= text.length) {
        return Position(nodeIndex, text.length);
      }
      while (newOffset < text.length &&
          !isWordCharacter(text.codeUnitAt(newOffset))) {
        newOffset++;
      }
      while (newOffset < text.length &&
          isWordCharacter(text.codeUnitAt(newOffset))) {
        newOffset++;
      }
    } else {
      if (newOffset <= 0) {
        return Position(nodeIndex, 0);
      }
      while (
          newOffset > 0 && !isWordCharacter(text.codeUnitAt(newOffset - 1))) {
        newOffset--;
      }
      while (newOffset > 0 && isWordCharacter(text.codeUnitAt(newOffset - 1))) {
        newOffset--;
      }
    }

    return Position(nodeIndex, newOffset);
  }

  bool isWordCharacter(int charCode) {
    return (charCode >= 0x30 && charCode <= 0x39) ||
        (charCode >= 0x41 && charCode <= 0x5A) ||
        (charCode >= 0x61 && charCode <= 0x7A);
  }
}

class _NodeLocation {
  final int nodeIndex;
  final int offsetInNode;
  _NodeLocation(this.nodeIndex, this.offsetInNode);
}
