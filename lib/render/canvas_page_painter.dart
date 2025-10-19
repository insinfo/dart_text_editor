// Arquivo: lib/render/canvas_page_painter.dart (CORRIGIDO)
import 'dart:async';
import 'package:canvas_text_editor/core/inline_attributes.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/image_node.dart';
import 'package:canvas_text_editor/core/selection.dart';
import 'package:canvas_text_editor/layout/page_layout.dart';
import 'package:canvas_text_editor/layout/text_position.dart';
import 'package:canvas_text_editor/render/editor_theme.dart';
import 'package:canvas_text_editor/layout/page_constraints.dart';
import 'package:canvas_text_editor/util/web_ui.dart';
import 'package:canvas_text_editor/layout/paragraph_layouter.dart';
import 'package:canvas_text_editor/render/measure_cache.dart';
import 'package:canvas_text_editor/util/dom_api.dart';

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
    // CORREÇÃO B3: Um único save/restore por página.
    ctx.save();

    ctx.textBaseline = 'alphabetic';
    // A translação agora acontece dentro do loop de pintura do editor
    // ctx.translate(0, page.yOrigin);

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

          var xLineOffset = block.x + constraints.marginLeft;

          final lineBaseHeight = line.height /
              (paragraphNode.attributes.lineSpacing * constraints.zoomLevel);
          yLineOffset += lineBaseHeight;

          // Lógica de alinhamento
          switch (paragraphNode.attributes.align) {
            case TextAlign.center:
              xLineOffset += (block.width - line.width) / 2;
              break;
            case TextAlign.right:
              xLineOffset += (block.width - line.width);
              break;
            default: // left or justify
              break;
          }

          for (final span in line.spans) {
            final attributes = span.run.attributes;
            ctx.font = _fontString(attributes, constraints.zoomLevel);
            ctx.fillStyle =
                attributes.fontColor ?? theme.fontColor.toRgbaString();

            // Lógica de pintura de seleção
            // TODO: Implementar pintura de seleção que abrange múltiplos spans/linhas/blocos

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
    ctx.fillRect(cursorPosition.x + 56.7, cursorPosition.y + 56.7, 1,
        cursorPosition.height);
    ctx.restore();
  }
}
