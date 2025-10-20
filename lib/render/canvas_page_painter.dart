// C:\MyDartProjects\canvas_text_editor\lib\render\canvas_page_painter.dart
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
import 'package:dart_text_editor/layout/paginator.dart';
import 'package:dart_text_editor/layout/paragraph_layout_result.dart';

class CanvasPagePainter {
  final EditorTheme theme;
  final ParagraphLayouter layouter;
  final void Function() repaint;
  final Paginator paginator;
  final WindowApi window;

  bool _cursorVisible = true;
  Timer? _cursorTimer;

  CanvasPagePainter(this.theme, MeasureCache measureCache, this.repaint, this.paginator, this.window)
      : layouter = ParagraphLayouter(measureCache) {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _cursorVisible = !_cursorVisible;
      repaint();
    });
  }

  void dispose() {
    _cursorTimer?.cancel();
  }

  void paint(CanvasRenderingContext2DApi ctx, PageLayout page,
      PageConstraints constraints, Selection selection) {
    ctx.save();
    ctx.textBaseline = 'alphabetic';
    ctx.beginPath();
    ctx.rect(0, 0, constraints.width, constraints.height);
    ctx.clip();
    _drawPageBackground(ctx, constraints);

    for (final block in page.blocks) {
      ctx.save();
      final relativeBlockY = block.y;
      final relativeBlockX = block.x;
      ctx.translate(relativeBlockX, relativeBlockY);

      if (block.node is ParagraphNode) {
        final paragraphNode = block.node as ParagraphNode;
        final layoutResult = block.layoutResult ??
            layouter.layout(
              paragraphNode,
              PageConstraints(width: block.width, height: block.height),
            );

        if (!selection.isCollapsed &&
            block.nodeIndex >= selection.start.node &&
            block.nodeIndex <= selection.end.node) {
          _paintSelectionForBlock(ctx, layoutResult, selection, block.nodeIndex, constraints);
        }

        var yLineBaseline = 0.0;
        for (var lineIndex = 0; lineIndex < layoutResult.lines.length; lineIndex++) {
          final line = layoutResult.lines[lineIndex];
          double maxFontSizeInLine = 16.0 * constraints.zoomLevel;
          if (line.spans.isNotEmpty) {
            maxFontSizeInLine = line.spans
                .map((s) => (s.run.attributes.fontSize ?? 16.0) * constraints.zoomLevel)
                .reduce((a, b) => a > b ? a : b);
          }
          yLineBaseline += maxFontSizeInLine * 0.8;

          var xLineOffset = 0.0;
          switch (paragraphNode.attributes.align) {
            case TextAlign.center:
              xLineOffset = (block.width - line.width) / 2;
              break;
            case TextAlign.right:
              xLineOffset = block.width - line.width;
              break;
            default:
              break;
          }
          xLineOffset = xLineOffset.clamp(0.0, double.infinity);

          for (final span in line.spans) {
            if (span.hidden) continue;
            final attributes = span.run.attributes;
            ctx.font = _fontString(attributes, constraints.zoomLevel);
            final spanWidth = layouter.measureCache.measure(span.run.text, attributes).width;

            if (attributes.backgroundColor != null) {
              ctx.fillStyle = attributes.backgroundColor!;
              ctx.fillRect(xLineOffset, yLineBaseline - maxFontSizeInLine * 0.8, spanWidth, line.height);
            }

            ctx.fillStyle = attributes.fontColor ?? theme.fontColor.toRgbaString();
            ctx.fillText(span.run.text, xLineOffset, yLineBaseline);
            xLineOffset += spanWidth;
          }
          yLineBaseline += line.height - (maxFontSizeInLine * 0.8);
        }
      } else if (block.node is ImageNode) {
        ctx.fillStyle = 'grey';
        ctx.fillRect(0, 0, block.width, block.height);
        ctx.strokeStyle = 'black';
        ctx.strokeRect(0, 0, block.width, block.height);
        ctx.fillStyle = 'black';
        ctx.fillText('Image Placeholder', 5, 20);
      }

      ctx.restore();
    }

    ctx.restore();
  }

  void _paintSelectionForBlock(
      CanvasRenderingContext2DApi ctx,
      ParagraphLayoutResult layoutResult,
      Selection selection,
      int blockNodeIndex,
      PageConstraints constraints) {
    ctx.save();
    ctx.fillStyle = theme.selectionColor.withAlpha(100).toRgbaString();

    var yLineTop = 0.0;

    for (var lineIndex = 0; lineIndex < layoutResult.lines.length; lineIndex++) {
      final line = layoutResult.lines[lineIndex];
      if (line.spans.isEmpty) {
        yLineTop += line.height;
        continue;
      }

      final lineStartOffset = line.spans.first.startInNode;
      final lineEndOffset = line.spans.last.endInNode;

      final selStartNode = selection.start.node;
      final selEndNode = selection.end.node;
      final selStartOffset = selection.start.offset;
      final selEndOffset = selection.end.offset;

      if (blockNodeIndex > selStartNode || (blockNodeIndex == selStartNode && lineEndOffset > selStartOffset)) {
        if (blockNodeIndex < selEndNode || (blockNodeIndex == selEndNode && lineStartOffset < selEndOffset)) {
          final selectionStartOnLine = (blockNodeIndex == selStartNode)
              ? selStartOffset.clamp(lineStartOffset, lineEndOffset)
              : lineStartOffset;

          final selectionEndOnLine = (blockNodeIndex == selEndNode)
              ? selEndOffset.clamp(lineStartOffset, lineEndOffset)
              : lineEndOffset;

          if (selectionEndOnLine > selectionStartOnLine) {
            final columnStart = selectionStartOnLine - lineStartOffset;
            final columnEnd = selectionEndOnLine - lineStartOffset;

            final startCoords = layouter.getCaretXY(layoutResult, lineIndex, columnStart);
            final endCoords = layouter.getCaretXY(layoutResult, lineIndex, columnEnd);

            ctx.fillRect(
              startCoords.dx,
              yLineTop,
              endCoords.dx - startCoords.dx,
              line.height,
            );
          }
        }
      }
      yLineTop += line.height;
    }
    ctx.restore();
  }

  static String _fontString(InlineAttributes attributes, double zoomLevel) {
    final fontSize = (attributes.fontSize ?? 16.0) * zoomLevel;
    final fontFamily = attributes.fontFamily;
    final fontWeight = attributes.bold ? 'bold ' : '';
    final fontStyle = attributes.italic ? 'italic ' : '';
    return '$fontStyle$fontWeight${fontSize.toStringAsFixed(1)}px "$fontFamily"';
  }

  void paintCursor(CanvasRenderingContext2DApi ctx, TextPosition cursorPosition) {
    if (!_cursorVisible) return;
    final pc = paginator.lastConstraints;
    if (pc == null) return;

    PageLayout? cursorPage;
    for (final page in paginator.lastPaginatedPages) {
      final pageBottom = page.yOrigin + pc.marginTop + pc.height + pc.marginBottom;
      if (cursorPosition.y >= page.yOrigin && cursorPosition.y < pageBottom) {
        cursorPage = page;
        break;
      }
    }
    cursorPage ??= (paginator.lastPaginatedPages.isNotEmpty ? paginator.lastPaginatedPages.last : null);
    if (cursorPage == null) return;

    ctx.save();
    ctx.fillStyle = theme.cursorColor.toRgbaString();

    final cursorYRelativeToPage = cursorPosition.y - cursorPage.yOrigin;
    final cursorXRelativeToPage = cursorPosition.x;

    const cursorWidth = 1.0;
    ctx.fillRect(cursorXRelativeToPage, cursorYRelativeToPage, cursorWidth, cursorPosition.height);
    ctx.restore();
  }

  void _drawPageBackground(CanvasRenderingContext2DApi ctx, PageConstraints constraints) {
    ctx.save();
    ctx.fillStyle = 'white';
    ctx.fillRect(0, 0, constraints.width, constraints.height);
    ctx.strokeStyle = '#CCCCCC';
    ctx.lineWidth = 1.0 / (window.devicePixelRatio * constraints.zoomLevel);
    ctx.strokeRect(0.5, 0.5, constraints.width - 1, constraints.height - 1);
    ctx.restore();
  }
}
