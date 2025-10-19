// Arquivo: lib/render/canvas_page_painter.dart (COMPLETO E CORRIGIDO)
import 'dart:async';

import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/image_node.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/layout/page_layout.dart';
import 'package:dart_text_editor/layout/text_position.dart';
import 'package:dart_text_editor/render/editor_theme.dart';
import 'package:dart_text_editor/layout/page_constraints.dart';
import 'package:dart_text_editor/util/web_ui.dart';
import 'package:dart_text_editor/layout/paragraph_layouter.dart';
import 'package:dart_text_editor/render/measure_cache.dart';
import 'package:dart_text_editor/util/dom_api.dart';

class CanvasPagePainter {
  final EditorTheme theme;
  final ParagraphLayouter layouter;
  final void Function() repaint;

  bool _cursorVisible = true;
  Timer? _cursorTimer;

  CanvasPagePainter(this.theme, MeasureCache measureCache, this.repaint)
      : layouter = ParagraphLayouter(measureCache) {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _cursorVisible = !_cursorVisible;
      repaint();
    });
  }

  void dispose() {
    _cursorTimer?.cancel();
  }

  static String _fontString(InlineAttributes attributes, double zoomLevel) {
    final fontSize = (attributes.fontSize ?? 16.0) * zoomLevel;
    final fontFamily = attributes.fontFamily;
    return '${attributes.italic ? 'italic ' : ''}${attributes.bold ? 'bold ' : ''}${fontSize}px $fontFamily';
  }

  void paint(CanvasRenderingContext2DApi ctx, PageLayout page,
      PageConstraints constraints, Selection selection) {
    ctx.save();

    ctx.textBaseline = 'alphabetic';

    ctx.beginPath();
    ctx.rect(
        0,
        0,
        constraints.width + constraints.marginLeft + constraints.marginRight,
        constraints.height + constraints.marginTop + constraints.marginBottom);
    ctx.clip();

    _drawPageBackground(ctx, constraints);

    for (final block in page.blocks) {
      if (block.node is ParagraphNode) {
        final paragraphNode = block.node as ParagraphNode;
        final blockConstraints = PageConstraints(
            width: block.width,
            height: block.height,
            zoomLevel: constraints.zoomLevel);
        final layoutResult = layouter.layout(paragraphNode, blockConstraints);

        var yLineOffset = block.y + constraints.marginTop;

        for (var lineIndex = 0;
            lineIndex < layoutResult.lines.length;
            lineIndex++) {
          final line = layoutResult.lines[lineIndex];
          final lineBaseHeight = line.height /
              (paragraphNode.attributes.lineSpacing * constraints.zoomLevel);

          // Ponto de início da seleção (se houver nesta linha)
          final selStartNode = selection.start.node;
          final selEndNode = selection.end.node;
          final selStartOffset = selection.start.offset;
          final selEndOffset = selection.end.offset;

          // Lógica de pintura de seleção
          if (!selection.isCollapsed &&
              block.nodeIndex >= selStartNode &&
              block.nodeIndex <= selEndNode) {
            final firstSpan = line.spans.first;
            final lastSpan = line.spans.last;
            final lineStartOffset = firstSpan.startInNode;
            final lineEndOffset = lastSpan.endInNode;

            // Define o início e fim da seleção *nesta linha específica*
            final selectionStartOnLine = (block.nodeIndex == selStartNode)
                ? selStartOffset.clamp(lineStartOffset, lineEndOffset)
                : lineStartOffset;

            final selectionEndOnLine = (block.nodeIndex == selEndNode)
                ? selEndOffset.clamp(lineStartOffset, lineEndOffset)
                : lineEndOffset;

            if (selectionEndOnLine > selectionStartOnLine) {
              final columnStart = selectionStartOnLine - lineStartOffset;
              final columnEnd = selectionEndOnLine - lineStartOffset;
              final startCoords =
                  layouter.getCaretXY(layoutResult, lineIndex, columnStart);
              final endCoords =
                  layouter.getCaretXY(layoutResult, lineIndex, columnEnd);

              ctx.fillStyle = theme.selectionColor.toRgbaString();
              ctx.fillRect(
                  block.x + constraints.marginLeft + startCoords.dx,
                  yLineOffset,
                  endCoords.dx - startCoords.dx,
                  line.height);
            }
          }

          var xLineOffset = block.x + constraints.marginLeft;
          yLineOffset += lineBaseHeight;

          switch (paragraphNode.attributes.align) {
            case TextAlign.center:
              xLineOffset += (block.width - line.width) / 2;
              break;
            case TextAlign.right:
              xLineOffset += (block.width - line.width);
              break;
            default:
              break;
          }

          for (final span in line.spans) {
            if (span.hidden) continue;
            final attributes = span.run.attributes;
            ctx.font = _fontString(attributes, constraints.zoomLevel);
            ctx.fillStyle =
                attributes.fontColor ?? theme.fontColor.toRgbaString();

            ctx.fillText(span.run.text, xLineOffset, yLineOffset);
            xLineOffset +=
                layouter.measureCache.measure(span.run.text, attributes).width;
          }
          yLineOffset += line.height - lineBaseHeight;
        }
      } else if (block.node is ImageNode) {
        // Lógica de pintura para imagem
      }
    }

    ctx.restore();
  }

  void _drawPageBackground(
      CanvasRenderingContext2DApi ctx, PageConstraints constraints) {
    ctx.fillStyle = 'white';
    ctx.fillRect(
        0,
        0,
        constraints.width + constraints.marginLeft + constraints.marginRight,
        constraints.height + constraints.marginTop + constraints.marginBottom);
    ctx.strokeStyle = '#CCCCCC';
    ctx.lineWidth = 1;
    ctx.strokeRect(
        0.5,
        0.5,
        constraints.width +
            constraints.marginLeft +
            constraints.marginRight -
            1,
        constraints.height +
            constraints.marginTop +
            constraints.marginBottom -
            1);
  }

  void paintCursor(
      CanvasRenderingContext2DApi ctx, TextPosition cursorPosition) {
    if (!_cursorVisible) return;
    ctx.save();
    ctx.fillStyle = 'black';
    // Adiciona a margem da página às coordenadas do cursor
    final marginLeft = 56.7;
    final marginTop = 56.7;
    ctx.fillRect(cursorPosition.x + marginLeft, cursorPosition.y + marginTop, 1,
        cursorPosition.height);
    ctx.restore();
  }
}