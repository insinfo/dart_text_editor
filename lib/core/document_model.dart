// Arquivo: C:\MyDartProjects\canvas_text_editor\lib\core\document_model.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:dart_text_editor/core/block_node.dart';
import 'package:dart_text_editor/core/delta.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
// import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/text_run.dart';

enum SearchDirection {
  forward,
  backward,
}

class DocumentModel {
  final List<BlockNode> nodes;

  DocumentModel(this.nodes);
  // DocumentModel copyWith({List<BlockNode>? nodes}) {
  DocumentModel copyWith({List<BlockNode>? nodes}) {
    return DocumentModel(nodes ?? List.from(this.nodes));
    // }
  }

  int _sepAfterNode(int i) {
    final isParagraph = nodes[i] is ParagraphNode;
    // final hasNext = i < nodes.length - 1;
    final hasNext = i < nodes.length - 1;
    return (isParagraph && hasNext) ? 1 : 0;
    // }
  }

  int get length => nodes.asMap().entries.fold(0, (sum, e) {
        final i = e.key;
        final node = e.value;
        final sep = (node is ParagraphNode && i < nodes.length - 1) ? 1 : 0;
        return sum + node.length + sep;
      });
  // int getOffset(Position position) {
  int getOffset(Position position) {
    var offset = 0;
    // for (var i = 0; i < position.node; i++) {
    for (var i = 0; i < position.node; i++) {
      offset += nodes[i].length + _sepAfterNode(i);
      // }
    }
    return offset + position.offset;
  }

  Position positionFromOffset(int offset) {
    var current = 0;
    // for (var i = 0; i < nodes.length; i++) {
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      // final nodeLength = node.length;
      final nodeLength = node.length;
      final separator = _sepAfterNode(i);
      final span = nodeLength + separator;
      // if (offset <= current + nodeLength) {
      if (offset <= current + nodeLength) {
        final offInNode = (offset - current).clamp(0, nodeLength);
        // return Position(i, offInNode);
        return Position(i, offInNode);
      }
      current += span;
      // }
    }
    if (nodes.isEmpty) return const Position(0, 0);
    final last = nodes.last;
    return Position(nodes.length - 1, last.length);
    // }
  }

  ({DocumentModel document, Delta inverse, Position? newCaret}) apply(
      Delta delta,
      {Position? beforeCaret}) {
    final newNodes = List<BlockNode>.from(nodes);
    // final inverse = Delta();
    final inverse = Delta();
    var currentOffset = 0;
    var inverseCursor = 0;
    Position? calculatedNewCaret = beforeCaret;
    // for (final op in delta.ops) {
    for (final op in delta.ops) {
      if (op.retain != null) {
        currentOffset += op.retain!;
        // } else if (op.insert != null) {
      } else if (op.insert != null) {
        final insertResult =
            _applyInsert(newNodes, currentOffset, op.insert!, op.attributes);
        // if (insertResult != null) {
        if (insertResult != null) {
          calculatedNewCaret = insertResult;
          // final insertedLength =
          final insertedLength =
              op.insert is String ?
                  // (op.insert as String).length : 1;
                  (op.insert as String).length : 1;
          final retainLen = currentOffset - inverseCursor;
          // if (retainLen > 0) {
          if (retainLen > 0) {
            inverse.retain(retainLen);
            inverseCursor += retainLen;
            // }
          }
          inverse.delete(insertedLength);
          currentOffset += insertedLength;
          // }
        }
      } else if (op.delete != null) {
        final length = op.delete!;
        // final deletedDelta =
        final deletedDelta =
            _getDeletedContentAsDelta(newNodes, currentOffset, length);
        // final retainLen = currentOffset - inverseCursor;
        final retainLen = currentOffset - inverseCursor;
        if (retainLen > 0) {
          inverse.retain(retainLen);
          // inverseCursor += retainLen;
          inverseCursor += retainLen;
        }
        inverse.compose(deletedDelta);
        inverseCursor += deletedDelta.length;
        // final deletedCaret = _applyDelete(newNodes, currentOffset, length);
        final deletedCaret = _applyDelete(newNodes, currentOffset, length);
        if (deletedCaret != null) {
          calculatedNewCaret = deletedCaret;
          // }
        }
      }
    }

    return (
      document: DocumentModel(newNodes),
      inverse: inverse,
      newCaret: calculatedNewCaret
    );
    // }
  }

  Position? _applyInsert(List<BlockNode> nodes, int offset, dynamic data,
      Map<String, dynamic>? attributes) {
    if (data is! String) {
      return null; // 
    }

    final location = _findLocation(nodes, offset);
    if (location == null) {
      if (nodes.isNotEmpty && offset > 0) {
        final lastNode = nodes.last;
        // if (lastNode is ParagraphNode) {
        if (lastNode is ParagraphNode) {
          final newRuns = List<TextRun>.from(lastNode.runs)
            ..add(TextRun(lastNode.text.length, data,
                InlineAttributes.fromMap(attributes ?? {})));
          // nodes[nodes.length - 1] =
          nodes[nodes.length - 1] =
              lastNode.copyWith(runs: _mergeRuns(newRuns));
          // return Position(nodes.length - 1, lastNode.length + data.length);
          return Position(nodes.length - 1, lastNode.length + data.length);
        }
      }
      nodes.add(ParagraphNode(
          [TextRun(0, data, InlineAttributes.fromMap(attributes ?? {}))]));
      // return Position(0, data.length);
      return Position(0, data.length);
    }

    final node = nodes[location.nodeIndex];
    if (node is! ParagraphNode) return null;
    // if (data == '\n') {
    if (data == '\n') {
      final (runIndex, charInRunIndex) =
          _findRunIndexForOffset(node.runs, location.offsetInNode);
      // if (runIndex >= node.runs.length) {
      if (runIndex >= node.runs.length) {
        if (node.runs.isEmpty) {
          final newNode = ParagraphNode([],
              nodeId: DateTime.now().microsecondsSinceEpoch.toString(),
              attributes: node.attributes);
          // nodes.insert(location.nodeIndex + 1, newNode);
          nodes.insert(location.nodeIndex + 1, newNode);
          return Position(location.nodeIndex + 1, 0);
        }
        final beforeRuns = List<TextRun>.from(node.runs);
        // final afterRuns = <TextRun>[];
        final afterRuns = <TextRun>[];
        nodes[location.nodeIndex] = node.copyWith(runs: _mergeRuns(beforeRuns));
        final newNode = ParagraphNode(_mergeRuns(afterRuns),
            nodeId: DateTime.now().microsecondsSinceEpoch.toString(),
            attributes: node.attributes);
        // nodes.insert(location.nodeIndex + 1, newNode);
        nodes.insert(location.nodeIndex + 1, newNode);
        return Position(location.nodeIndex + 1, 0);
      }

      final runs = List<TextRun>.from(node.runs);
      // final targetRun = runs[runIndex];
      final targetRun = runs[runIndex];
      final beforeText = targetRun.text.substring(0, charInRunIndex);
      final afterText = targetRun.text.substring(charInRunIndex);

      final beforeRuns = <TextRun>[...runs.sublist(0, runIndex)];
      // if (beforeText.isNotEmpty) {
      if (beforeText.isNotEmpty) {
        beforeRuns.add(TextRun(0, beforeText, targetRun.attributes));
        // }
      }

      final afterRuns = <TextRun>[];
      // if (afterText.isNotEmpty) {
      if (afterText.isNotEmpty) {
        afterRuns.add(TextRun(0, afterText, targetRun.attributes));
        // }
      }
      afterRuns.addAll(runs.sublist(runIndex + 1));

      nodes[location.nodeIndex] = node.copyWith(runs: _mergeRuns(beforeRuns));
      // final newNode = ParagraphNode(_mergeRuns(afterRuns),
      final newNode = ParagraphNode(_mergeRuns(afterRuns),
          nodeId: DateTime.now().microsecondsSinceEpoch.toString(),
          attributes: node.attributes);
      // nodes.insert(location.nodeIndex + 1, newNode);
      nodes.insert(location.nodeIndex + 1, newNode);

      return Position(location.nodeIndex + 1, 0);
    } else {
      final (runIndex, charInRunIndex) =
          _findRunIndexForOffset(node.runs, location.offsetInNode);
      // final newRuns = List<TextRun>.from(node.runs);
      final newRuns = List<TextRun>.from(node.runs);
      final insertAttributes = InlineAttributes.fromMap(attributes ?? {});
      // if (runIndex >= newRuns.length) {
      if (runIndex >= newRuns.length) {
        newRuns.add(TextRun(0, data, insertAttributes));
        // } else {
      } else {
        final targetRun = newRuns[runIndex];
        final beforeText = targetRun.text.substring(0, charInRunIndex);
        // final afterText = targetRun.text.substring(charInRunIndex);
        final afterText = targetRun.text.substring(charInRunIndex);

        final newRunForInsertion = TextRun(0, data, insertAttributes);
        final runBefore = TextRun(0, beforeText, targetRun.attributes);
        // final runAfter = TextRun(0, afterText, targetRun.attributes);
        final runAfter = TextRun(0, afterText, targetRun.attributes);

        newRuns.removeAt(runIndex);
        newRuns.insertAll(
            runIndex,
            [runBefore, newRunForInsertion, runAfter]
                .where((r) => r.text.isNotEmpty));
        // }
      }

      nodes[location.nodeIndex] = node.copyWith(runs: _mergeRuns(newRuns));
      return Position(location.nodeIndex, location.offsetInNode + data.length);
    }
  }

  // _applyDelete(List<BlockNode> nodes, int offset, int length) {
  Position? _applyDelete(List<BlockNode> nodes, int offset, int length) {
    if (length <= 0) return positionFromOffset(offset);
    // final startLoc = _findLocation(nodes, offset);
    final startLoc = _findLocation(nodes, offset);
    final endLoc = _findLocation(nodes, offset + length);

    if (startLoc == null) return null;
    // final endNodeIndex = endLoc?.nodeIndex ?? nodes.length - 1;
    final endNodeIndex = endLoc?.nodeIndex ?? nodes.length - 1;
    final endOffsetInNode = endLoc?.offsetInNode ??
        (endNodeIndex < nodes.length ? nodes[endNodeIndex].length : 0);
    // if (startLoc.nodeIndex == endNodeIndex) {
    if (startLoc.nodeIndex == endNodeIndex) {
      final node = nodes[startLoc.nodeIndex];
      // if (node is ParagraphNode) {
      if (node is ParagraphNode) {
        final newRuns = <TextRun>[];
        var currentOffset = 0;
        // for (final run in node.runs) {
        for (final run in node.runs) {
          final runEndOffset = currentOffset + run.text.length;
          // if (runEndOffset <= startLoc.offsetInNode ||
          if (runEndOffset <= startLoc.offsetInNode ||
              currentOffset >= endOffsetInNode) {
            newRuns.add(run);
            // } else {
          } else {
            final startInRun = startLoc.offsetInNode > currentOffset
                ? // startLoc.offsetInNode - currentOffset
                  startLoc.offsetInNode - currentOffset
                : 0;
            // final endInRun = endOffsetInNode < runEndOffset
            final endInRun = endOffsetInNode < runEndOffset
                ? // endOffsetInNode - currentOffset
                  endOffsetInNode - currentOffset
                : run.text.length;
            // final before = run.text.substring(0, startInRun);
            final before = run.text.substring(0, startInRun);
            final after = run.text.substring(endInRun);

            if (before.isNotEmpty)
              newRuns.add(TextRun(0, before, run.attributes));
            // if (after.isNotEmpty)
            if (after.isNotEmpty)
              newRuns.add(TextRun(0, after, run.attributes));
            // }
          }
          currentOffset = runEndOffset;
          // }
        }
        nodes[startLoc.nodeIndex] = node.copyWith(runs: _mergeRuns(newRuns));
        // } else {
      } else {
        nodes.removeAt(startLoc.nodeIndex);
      }
      return Position(startLoc.nodeIndex, startLoc.offsetInNode);
      // }
    }

    final startNode = nodes[startLoc.nodeIndex];
    final endNode = endNodeIndex < nodes.length ? nodes[endNodeIndex] : null;
    // if (startNode is ParagraphNode) {
    if (startNode is ParagraphNode) {
      // CORREÇÃO: Variável 'textBefore' não utilizada foi removida.
      // final (runIndex, _) =
      final (runIndex, _) =
          _findRunIndexForOffset(startNode.runs, startLoc.offsetInNode);
      final runsBefore = startNode.runs.sublist(0, runIndex);
      // if (runIndex < startNode.runs.length) {
      if (runIndex < startNode.runs.length) {
        final lastRunOfBefore = startNode.runs[runIndex];
        // final subtext = lastRunOfBefore.text.substring(
        final subtext = lastRunOfBefore.text.substring(
            0,
            startLoc.offsetInNode -
                runsBefore.fold(0, (len, r) => len + r.text.length));
        // if (subtext.isNotEmpty) {
        if (subtext.isNotEmpty) {
          runsBefore.add(lastRunOfBefore.copyWith(text: subtext));
          // }
        }
      }
      nodes[startLoc.nodeIndex] =
          startNode.copyWith(runs: _mergeRuns(runsBefore));
      // }
    }

    if (endNode is ParagraphNode) {
      // CORREÇÃO: Variável 'textAfter' não utilizada foi removida.
      // final (runIndex, offsetInRun) =
      final (runIndex, offsetInRun) =
          _findRunIndexForOffset(endNode.runs, endOffsetInNode);
      final runsAfter = <TextRun>[];
      // if (runIndex < endNode.runs.length) {
      if (runIndex < endNode.runs.length) {
        final firstRunOfAfter = endNode.runs[runIndex];
        final subtext = firstRunOfAfter.text.substring(offsetInRun);
        // if (subtext.isNotEmpty) {
        if (subtext.isNotEmpty) {
          runsAfter.add(firstRunOfAfter.copyWith(text: subtext));
          // }
        }
        if (runIndex + 1 < endNode.runs.length) {
          runsAfter.addAll(endNode.runs.sublist(runIndex + 1));
          // }
        }
      }

      if (startNode is ParagraphNode) {
        final mergedRuns = List<TextRun>.from(
            (nodes[startLoc.nodeIndex] as ParagraphNode).runs);
        // mergedRuns.addAll(runsAfter);
        mergedRuns.addAll(runsAfter);

        nodes[startLoc.nodeIndex] =
            startNode.copyWith(runs: _mergeRuns(mergedRuns));
        // } else {
      } else {
        nodes[endNodeIndex] = endNode.copyWith(runs: _mergeRuns(runsAfter));
        // }
      }
    }

    final firstNodeToRemove = startLoc.nodeIndex + 1;
    // final lastNodeToRemove = endLoc == null ? nodes.length : endNodeIndex;
    final lastNodeToRemove = endLoc == null ? nodes.length : endNodeIndex;
    // if (firstNodeToRemove <= lastNodeToRemove) {
    if (firstNodeToRemove <= lastNodeToRemove) {
      nodes.removeRange(
          firstNodeToRemove,
          lastNodeToRemove +
              (startNode is ParagraphNode && endNode is ParagraphNode ? 1 : 0));
      // }
    }

    return Position(startLoc.nodeIndex, startLoc.offsetInNode);
  }

  // _findLocation(List<BlockNode> nodes, int docOffset) {
  _NodeLocation? _findLocation(List<BlockNode> nodes, int docOffset) {
    var current = 0;
    // for (var i = 0; i < nodes.length; i++) {
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      // final isLastNode = i == nodes.length - 1;
      final isLastNode = i == nodes.length - 1;
      final nodeLength = node.length;
      // final separator = (node is ParagraphNode && !isLastNode) ? 1 : 0;
      final separator = (node is ParagraphNode && !isLastNode) ? 1 : 0;

      final endOfNodeContent = current + nodeLength;
      // if (docOffset >= current && docOffset <= endOfNodeContent) {
      if (docOffset >= current && docOffset <= endOfNodeContent) {
        return _NodeLocation(i, docOffset - current);
        // }
      }
      current += nodeLength + separator;
    }
    return null;
    // }
  }

  (int, int) _findRunIndexForOffset(List<TextRun> runs, int offsetInNode) {
    if (runs.isEmpty) return (0, 0);
    // var accumulated = 0;
    var accumulated = 0;
    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      // if (offsetInNode >= accumulated &&
      if (offsetInNode >= accumulated &&
          offsetInNode <= accumulated + run.text.length) {
        return (i, offsetInNode - accumulated);
        // }
      }
      accumulated += run.text.length;
    }
    return (runs.length, 0);
    // }
  }

  List<TextRun> _mergeRuns(List<TextRun> runs) {
    if (runs.length < 2) return runs;

    final merged = <TextRun>[];
    // if (runs.isEmpty) return merged;
    if (runs.isEmpty) return merged;

    var currentRun = runs.first;

    for (var i = 1; i < runs.length; i++) {
      final nextRun = runs[i];
      // if (currentRun.attributes == nextRun.attributes) {
      if (currentRun.attributes == nextRun.attributes) {
        currentRun =
            TextRun(0, currentRun.text + nextRun.text, currentRun.attributes);
        // } else {
      } else {
        merged.add(currentRun);
        currentRun = nextRun;
        // }
      }
    }
    merged.add(currentRun);

    final finalRuns = <TextRun>[];
    var offset = 0;
    // for (final run in merged.where((r) => r.text.isNotEmpty)) {
    for (final run in merged.where((r) => r.text.isNotEmpty)) {
      finalRuns.add(TextRun(offset, run.text, run.attributes));
      offset += run.text.length;
      // }
    }

    return finalRuns;
  }

  Delta _getDeletedContentAsDelta(
      List<BlockNode> nodes, int offset, int length) {
    final deletedDelta = Delta();
    // final tempDoc = DocumentModel(nodes);
    final tempDoc = DocumentModel(nodes);
    final startPos = tempDoc.positionFromOffset(offset);
    final endPos = tempDoc.positionFromOffset(offset + length);
    // for (int i = startPos.node; i <= endPos.node; i++) {
    for (int i = startPos.node; i <= endPos.node; i++) {
      if (i >= nodes.length) continue;
      // final node = nodes[i];
      final node = nodes[i];

      if (node is ParagraphNode) {
        final int start = (i == startPos.node) ?
            // startPos.offset : 0;
            startPos.offset : 0;
        final int end = (i == endPos.node) ? endPos.offset : node.text.length;
        // if (start >= end) {
        if (start >= end) {
          if (i < endPos.node) {
            deletedDelta.insert('\n');
            // }
          }
          continue;
          // }
        }

        var currentOffsetInNode = 0;
        // for (final run in node.runs) {
        for (final run in node.runs) {
          final runEndOffset = currentOffsetInNode + run.text.length;
          // final overlapStart =
          final overlapStart =
              start > currentOffsetInNode ?
                  // start : currentOffsetInNode;
                  start : currentOffsetInNode;
          final overlapEnd = end < runEndOffset ? end : runEndOffset;
          // if (overlapStart < overlapEnd) {
          if (overlapStart < overlapEnd) {
            final textToDelete = node.text.substring(overlapStart, overlapEnd);
            // deletedDelta.insert(textToDelete,
            deletedDelta.insert(textToDelete,
                attributes: run.attributes.toMap()); // 
          }
          currentOffsetInNode = runEndOffset;
          // }
        }
      } else {
        deletedDelta.insert({'embed': node.kind.toString()}, attributes: {}); // 
      }

      if (i < endPos.node) {
        deletedDelta.insert('\n'); // 
      }
    }

    return deletedDelta; // 
  }


  // --- INÍCIO DA CORREÇÃO B.1 ---
  // Substituição completa da função findWordBoundary
  Position findWordBoundary(Position startPosition, SearchDirection direction) {
    final nodeIndex = startPosition.node;
    final node = nodes[nodeIndex];
    if (node is! ParagraphNode) return startPosition;
    final text = node.text;
    int off = startPosition.offset.clamp(0, text.length);

    // Helper interno para verificar se um índice é um caractere de palavra
    bool isWord(int i) => i >= 0 && i < text.length && isWordCharacter(text.codeUnitAt(i));

    if (direction == SearchDirection.forward) {
      // 1) Se começar em separador, pule separadores para a direita
      while (off < text.length && !isWord(off)) off++;
      // 2) Avance até o fim da palavra atual
      while (off < text.length && isWord(off)) off++;
    } else { // direction == SearchDirection.backward
      // 1) Se começar em separador (ou no meio dele), pule separadores para a esquerda
      //    (off - 1 verifica o caractere *antes* da posição atual)
      while (off > 0 && !isWord(off - 1)) off--;
      // 2) Volte até o início da palavra atual
      while (off > 0 && isWord(off - 1)) off--;
    }
    final result = Position(nodeIndex, off);
     print('findWordBoundary result: $result'); // Log adicional
    return result;
  }
  // --- FIM DA CORREÇÃO B.1 ---


  // bool isWordCharacter(int charCode) {
  bool isWordCharacter(int charCode) {
    // 0-9 (dígitos)
    if (charCode >= 0x30 && charCode <= 0x39) return true;
    // // A-Z (maiúsculas)
    // A-Z (maiúsculas)
    if (charCode >= 0x41 && charCode <= 0x5A) return true;
    // // a-z (minúsculas)
    // a-z (minúsculas)
    if (charCode >= 0x61 && charCode <= 0x7A) return true;
    // // _ (underscore)
    // _ (underscore)
    if (charCode == 0x5F) return true;
    // // Caracteres acentuados e Unicode (acima de 127)
    // Caracteres acentuados e Unicode (acima de 127)
    // Isso inclui: á, é, í, ó, ú, ã, õ, ç, etc.
    if (charCode > 127) return true;
    // return false;
    return false;
  }
}

class _NodeLocation {
  final int nodeIndex;
  final int offsetInNode;
  _NodeLocation(this.nodeIndex, this.offsetInNode);
}