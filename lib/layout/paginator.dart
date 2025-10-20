// C:\MyDartProjects\canvas_text_editor\lib\layout\paginator.dart
import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/image_node.dart';
import 'package:dart_text_editor/core/list_node.dart';
import 'package:dart_text_editor/core/table_node.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/layout/page_constraints.dart';
import 'package:dart_text_editor/layout/page_layout.dart';
import 'package:dart_text_editor/layout/paragraph_layouter.dart';
import 'package:dart_text_editor/layout/table_layouter.dart';
import 'package:dart_text_editor/layout/text_position.dart';
import 'package:dart_text_editor/render/measure_cache.dart';
import 'package:dart_text_editor/render/positioned_block.dart';

class Paginator {
  final MeasureCache measureCache;
  late final ParagraphLayouter layouter;

  Paginator(this.measureCache) {
    layouter = ParagraphLayouter(measureCache);
  }

  PageConstraints? _lastConstraints;
  List<PageLayout> _lastPaginatedPages = [];
  List<PageLayout> get lastPaginatedPages => _lastPaginatedPages;
  PageConstraints? get lastConstraints => _lastConstraints;

  Position? keyboardAnchor;
  double? desiredX;

  List<PageLayout> paginate(DocumentModel doc, PageConstraints constraints) {
    _lastConstraints = constraints;
    final pages = <PageLayout>[];

    var currentPageBlocks = <PositionedBlock>[];
    var currentPageHeight = 0.0;
    var yPos = constraints.marginTop;
    var pageIndex = 0;
    const pageGapPx = 32.0;

    void commitPage() {
      final pageHeightPx =
          constraints.marginTop + constraints.height + constraints.marginBottom;
      final yOrigin = pageIndex * (pageHeightPx + pageGapPx);
      pages.add(PageLayout(
        pageIndex: pageIndex,
        yOrigin: yOrigin,
        blocks: List.from(currentPageBlocks),
      ));
      currentPageBlocks.clear();
      currentPageHeight = 0.0;
      yPos = constraints.marginTop;
      pageIndex++;
    }

    for (var i = 0; i < doc.nodes.length; i++) {
      final node = doc.nodes[i];

      if (node is ParagraphNode) {
        final layout = layouter.layout(
          node,
          PageConstraints(width: constraints.width, height: constraints.height),
        );
        final blockHeight = layout.height;

        if (currentPageHeight + blockHeight > constraints.height &&
            currentPageBlocks.isNotEmpty) {
          commitPage();
        }

        currentPageBlocks.add(PositionedBlock(
          node: node,
          nodeIndex: i,
          x: constraints.marginLeft,
          y: yPos,
          width: constraints.width,
          height: blockHeight,
        ));

        currentPageHeight += blockHeight + node.attributes.spacingAfter;
        yPos += blockHeight + node.attributes.spacingAfter;
      } else if (node is ImageNode) {
        final imageWidth = node.width ?? constraints.width * 0.5;
        final imageHeight = node.height ?? imageWidth * 0.75;

        if (currentPageHeight + imageHeight > constraints.height &&
            currentPageBlocks.isNotEmpty) {
          commitPage();
        }

        currentPageBlocks.add(PositionedBlock(
          node: node,
          nodeIndex: i,
          x: constraints.marginLeft,
          y: yPos,
          width: imageWidth,
          height: imageHeight,
        ));

        currentPageHeight += imageHeight;
        yPos += imageHeight;
      } else if (node is ListNode) {
        final listHeight = node.items.length * 20.0;

        if (currentPageHeight + listHeight > constraints.height &&
            currentPageBlocks.isNotEmpty) {
          commitPage();
        }

        currentPageBlocks.add(PositionedBlock(
          node: node,
          nodeIndex: i,
          x: constraints.marginLeft,
          y: yPos,
          width: constraints.width,
          height: listHeight,
        ));

        currentPageHeight += listHeight;
        yPos += listHeight;
      } else if (node is TableNode) {
        final tableLayouter = TableLayouter();
        final layoutResult = tableLayouter.layout(node, constraints);

        if (currentPageHeight + layoutResult.height > constraints.height &&
            currentPageBlocks.isNotEmpty) {
          commitPage();
        }

        currentPageBlocks.add(PositionedBlock(
          node: node,
          nodeIndex: i,
          x: constraints.marginLeft,
          y: yPos,
          width: constraints.width,
          height: layoutResult.height,
        ));

        currentPageHeight += layoutResult.height;
        yPos += layoutResult.height;
      }
    }

    commitPage();
    _lastPaginatedPages = pages;
    return pages;
  }

  Position? getLineStart(Position position) {
    for (final page in _lastPaginatedPages) {
      for (final block in page.blocks) {
        if (block.nodeIndex == position.node && block.node is ParagraphNode) {
          final paragraphNode = block.node as ParagraphNode;
          final layoutResult =
              layouter.layout(paragraphNode, PageConstraints(width: block.width, height: block.height));

          var offsetInNode = 0;
          for (var i = 0; i < layoutResult.lines.length; i++) {
            final line = layoutResult.lines[i];
            final lineLen = line.spans.fold<int>(0, (p, s) => p + s.run.text.length);
            if (position.offset >= offsetInNode &&
                position.offset <= offsetInNode + lineLen) {
              return Position(position.node, offsetInNode);
            }
            offsetInNode += lineLen;
          }
        }
      }
    }
    return null;
  }

  Position? getLineEnd(Position position) {
    for (final page in _lastPaginatedPages) {
      for (final block in page.blocks) {
        if (block.nodeIndex == position.node && block.node is ParagraphNode) {
          final paragraphNode = block.node as ParagraphNode;
          final layoutResult =
              layouter.layout(paragraphNode, PageConstraints(width: block.width, height: block.height));

          var offsetInNode = 0;
          for (var i = 0; i < layoutResult.lines.length; i++) {
            final line = layoutResult.lines[i];
            final lineLen = line.spans.fold<int>(0, (p, s) => p + s.run.text.length);
            if (position.offset >= offsetInNode &&
                position.offset <= offsetInNode + lineLen) {
              return Position(position.node, offsetInNode + lineLen);
            }
            offsetInNode += lineLen;
          }
        }
      }
    }
    return null;
  }

  TextPosition? screenPos(Position position) {
    for (final page in _lastPaginatedPages) {
      for (final block in page.blocks) {
        if (block.nodeIndex != position.node) continue;

        if (block.node is ParagraphNode) {
          final paragraphNode = block.node as ParagraphNode;
          final layoutResult =
              layouter.layout(paragraphNode, PageConstraints(width: block.width, height: block.height));

          var offsetInNode = 0;
          for (var i = 0; i < layoutResult.lines.length; i++) {
            final line = layoutResult.lines[i];
            final lineLen = line.spans.fold<int>(0, (p, s) => p + s.run.text.length);

            if (offsetInNode + lineLen >= position.offset) {
              final col = position.offset - offsetInNode;
              final local = layouter.getCaretXY(layoutResult, i, col);
              return TextPosition(
                block.x + local.dx,
                page.yOrigin + block.y + local.dy,
                line.height,
              );
            }
            offsetInNode += lineLen;
          }

          if (position.offset == offsetInNode) {
            final lastIdx = layoutResult.lines.isNotEmpty ? layoutResult.lines.length - 1 : 0;
            final lastLine = layoutResult.lines.isNotEmpty ? layoutResult.lines.last : null;
            final col = lastLine?.spans.fold<int>(0, (p, s) => p + s.run.text.length) ?? 0;
            final local = layouter.getCaretXY(layoutResult, lastIdx, col);
            return TextPosition(
              block.x + local.dx,
              page.yOrigin + block.y + local.dy,
              lastLine?.height ?? 16.0,
            );
          }
        } else {
          return TextPosition(block.x, page.yOrigin + block.y, block.height);
        }
      }
    }
    return null;
  }

  Position? getPositionFromScreen(double x, double y) {
    if (_lastPaginatedPages.isEmpty || _lastConstraints == null) {
      return const Position(0, 0);
    }

    final pc = _lastConstraints!;
    int pageIndex = -1;
    for (var i = 0; i < _lastPaginatedPages.length; i++) {
      final top = _lastPaginatedPages[i].yOrigin;
      final bottom = top + pc.marginTop + pc.height + pc.marginBottom;
      if (y >= top && y < bottom) {
        pageIndex = i;
        break;
      }
    }
    if (pageIndex < 0) pageIndex = (y < _lastPaginatedPages.first.yOrigin) ? 0 : _lastPaginatedPages.length - 1;
    final page = _lastPaginatedPages[pageIndex];

    final yInPage = y - page.yOrigin;
    final xInPage = x;

    PositionedBlock target = page.blocks.first;
    bool found = false;
    for (final b in page.blocks) {
      if (yInPage >= b.y && yInPage < b.y + b.height) {
        target = b;
        found = true;
        break;
      }
    }
    if (!found) {
      double best = double.infinity;
      for (final b in page.blocks) {
        double dy = 0.0;
        if (yInPage < b.y) {
          dy = b.y - yInPage;
        } else if (yInPage > b.y + b.height) {
          dy = yInPage - (b.y + b.height);
        }
        if (dy < best) {
          best = dy;
          target = b;
        }
      }
    }

    final blockX = (xInPage - target.x).clamp(0.0, target.width);
    final blockY = (yInPage - target.y).clamp(0.0, target.height - 0.0001);

    if (target.node is ParagraphNode) {
      final paragraphNode = target.node as ParagraphNode;
      final layout = layouter.layout(
        paragraphNode,
        PageConstraints(width: target.width, height: target.height),
      );
      final idx = layouter.getIndexFromXY(layout, blockX, blockY);
      return Position(target.nodeIndex, idx);
    } else {
      return Position(target.nodeIndex, 0);
    }
  }
}
