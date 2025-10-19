import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/paragraph_node.dart';
import 'package:canvas_text_editor/core/image_node.dart';
import 'package:canvas_text_editor/core/list_node.dart';
import 'package:canvas_text_editor/core/table_node.dart';
import 'package:canvas_text_editor/core/position.dart';
import 'package:canvas_text_editor/layout/page_constraints.dart';
import 'package:canvas_text_editor/layout/page_layout.dart';
import 'package:canvas_text_editor/layout/paragraph_layouter.dart';
import 'package:canvas_text_editor/layout/table_layouter.dart';
import 'package:canvas_text_editor/layout/text_position.dart';
import 'package:canvas_text_editor/render/measure_cache.dart';
import 'package:canvas_text_editor/render/positioned_block.dart';

class Paginator {
  final MeasureCache measureCache;
  final double zoomLevel;
  List<PageLayout> _lastPaginatedPages = [];

  List<PageLayout> get lastPaginatedPages => _lastPaginatedPages;

  Paginator(this.measureCache, {this.zoomLevel = 1.0});

  List<PageLayout> paginate(DocumentModel doc, PageConstraints constraints) {
    final pages = <PageLayout>[];
    final layouter = ParagraphLayouter(measureCache);

    var currentPageBlocks = <PositionedBlock>[];
    var currentPageHeight = 0.0;
    var yPos = constraints.marginTop;
    var pageIndex = 0;
    const pageGapPx = 32.0; // As suggested in TODO.md

    void createPage() {
      if (currentPageBlocks.isNotEmpty) {
        final pageHeightPx = constraints.marginTop + constraints.height + constraints.marginBottom; // Total height of a page in px
        final yOrigin = pageIndex * (pageHeightPx + pageGapPx);
        pages.add(PageLayout(pageIndex: pageIndex, yOrigin: yOrigin, blocks: List.from(currentPageBlocks)));
        currentPageBlocks.clear();
        currentPageHeight = 0.0;
        yPos = constraints.marginTop;
        pageIndex++;
      }
    }

    for (var i = 0; i < doc.nodes.length; i++) {
      final node = doc.nodes[i];
      
      if (node is ParagraphNode) {
        final result = layouter.layout(node, constraints);
        final blockHeight = result.height;

        final contentHeight = constraints.height;
        if (currentPageHeight + blockHeight > contentHeight) {
          createPage();
        }

        currentPageBlocks.add(PositionedBlock(
          node: node,
          nodeIndex: i,
          x: constraints.marginLeft,
          y: yPos, // This yPos is relative to the current page's top margin
          width: constraints.width,
          height: blockHeight,
        ));
        currentPageHeight += blockHeight;
        yPos += blockHeight;

        // Add spacing after paragraph
        currentPageHeight += node.attributes.spacingAfter;
        yPos += node.attributes.spacingAfter;
        
      } else if (node is ImageNode) {
        // Simple image layout - use specified dimensions or defaults
        final imageWidth = node.width ?? constraints.width * 0.5;
        final imageHeight = node.height ?? imageWidth * 0.75; // Default aspect ratio
        
        if (currentPageHeight + imageHeight > constraints.height) {
          createPage();
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
        // Simple list layout - calculate height based on number of items
        final listHeight = node.items.length * 20.0; // 20px per item
        
        if (currentPageHeight + listHeight > constraints.height) {
          createPage();
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
        
        if (currentPageHeight + layoutResult.height > constraints.height) {
          createPage();
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

    if (currentPageBlocks.isNotEmpty) {
      createPage();
    }

    _lastPaginatedPages = pages;
    return pages;
  }

  Position? getLineStart(Position position) {
    for (final page in _lastPaginatedPages) {
      for (final block in page.blocks) {
        if (block.nodeIndex == position.node && block.node is ParagraphNode) {
          final paragraphNode = block.node as ParagraphNode;
          final layouter = ParagraphLayouter(measureCache);
          final layoutResult = layouter.layout(paragraphNode, PageConstraints(width: block.width, height: block.height));

          var offsetInNode = 0;
          for (var lineIndex = 0; lineIndex < layoutResult.lines.length; lineIndex++) {
            final line = layoutResult.lines[lineIndex];
            final lineLength = line.spans.map((s) => s.run.text.length).fold(0, (p, c) => p + c);

            if (position.offset >= offsetInNode && position.offset <= offsetInNode + lineLength) {
              return Position(position.node, offsetInNode);
            }
            offsetInNode += lineLength;
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
          final layouter = ParagraphLayouter(measureCache);
          final layoutResult = layouter.layout(paragraphNode, PageConstraints(width: block.width, height: block.height));

          var offsetInNode = 0;
          for (var lineIndex = 0; lineIndex < layoutResult.lines.length; lineIndex++) {
            final line = layoutResult.lines[lineIndex];
            final lineLength = line.spans.map((s) => s.run.text.length).fold(0, (p, c) => p + c);

            if (position.offset >= offsetInNode && position.offset <= offsetInNode + lineLength) {
              return Position(position.node, offsetInNode + lineLength);
            }
            offsetInNode += lineLength;
          }
        }
      }
    }
    return null;
  }

  TextPosition? screenPos(Position position) {
    for (final page in _lastPaginatedPages) {
      for (final block in page.blocks) {
        if (block.nodeIndex == position.node) {
          if (block.node is ParagraphNode) {
            final paragraphNode = block.node as ParagraphNode;
            final layouter = ParagraphLayouter(measureCache);
            final layoutResult = layouter.layout(paragraphNode, PageConstraints(width: block.width, height: block.height));

            var offsetInNode = 0;
            for (var lineIndex = 0; lineIndex < layoutResult.lines.length; lineIndex++) {
              final line = layoutResult.lines[lineIndex];
              final lineLength = line.spans.map((s) => s.run.text.length).fold(0, (p, c) => p + c);

              if (offsetInNode + lineLength >= position.offset) {
                // The position is in this line
                final columnInLine = position.offset - offsetInNode;
                final localOffset = layouter.getCaretXY(layoutResult, lineIndex, columnInLine);
                // Add page.yOrigin to the y coordinate
                return TextPosition(block.x + localOffset.dx, page.yOrigin + block.y + localOffset.dy, line.height);
              }
              offsetInNode += lineLength;
            }
            // Position might be at the very end of the paragraph
            if (position.offset == offsetInNode) {
                final lineIndex = layoutResult.lines.isNotEmpty ? layoutResult.lines.length - 1 : 0;
                final lastLine = layoutResult.lines.isNotEmpty ? layoutResult.lines.last : null;
                final columnInLine = lastLine?.spans.map((s) => s.run.text.length).fold(0, (p, c) => p + c) ?? 0;
                final localOffset = layouter.getCaretXY(layoutResult, lineIndex, columnInLine);
                // Add page.yOrigin to the y coordinate
                return TextPosition(block.x + localOffset.dx, page.yOrigin + block.y + localOffset.dy, lastLine?.height ?? 16.0);
            }
          } else if (block.node is ImageNode) {
            // For images, return position at the top-left corner
            return TextPosition(block.x, page.yOrigin + block.y, block.height);
          } else if (block.node is ListNode) {
            // For lists, we'd need to implement list-specific positioning
            // For now, return a simple position
            return TextPosition(block.x, page.yOrigin + block.y, block.height);
          } else if (block.node is TableNode) {
            // For tables, we'd need to implement table-specific positioning
            // For now, return a simple position
            return TextPosition(block.x, page.yOrigin + block.y, block.height);
          }
          return null; // Should not happen if position is valid
        }
      }
    }
    return null;
  }

  Position? getPositionFromScreen(double x, double y) {
    for (final page in _lastPaginatedPages) {
      // Subtract page.yOrigin from the y coordinate to get local y within the page
      final localYInPage = y - page.yOrigin;
      for (final block in page.blocks) {
        if (localYInPage >= block.y && localYInPage < block.y + block.height) {
          if (block.node is ParagraphNode) {
            final paragraphNode = block.node as ParagraphNode;
            final layouter = ParagraphLayouter(measureCache);
            final layoutResult = layouter.layout(paragraphNode, PageConstraints(width: block.width, height: block.height));
            final localX = x - block.x;
            final localY = localYInPage - block.y; // localY relative to block

            // Find which line was clicked
            var lineIndex = 0;
            var yOffset = 0.0;
            for (var i = 0; i < layoutResult.lines.length; i++) {
              final currentLine = layoutResult.lines[i];
              if (localY >= yOffset && localY < yOffset + currentLine.height) {
                lineIndex = i;
                break;
              }
              yOffset += currentLine.height;
            }

            // Calculate offset up to the start of the clicked line
            var offsetInNode = 0;
            for (var i = 0; i < lineIndex; i++) {
              offsetInNode += layoutResult.lines[i].spans.map((s) => s.run.text.length).fold(0, (p, c) => p + c);
            }

            // Get the column within the line and add it
            final columnInLine = layouter.getIndexFromXY(layoutResult, localX, localY);
            offsetInNode += columnInLine;

            return Position(block.nodeIndex, offsetInNode);
          } else if (block.node is ImageNode) {
            // For images, return position 0 (beginning of image)
            return Position(block.nodeIndex, 0);
          } else if (block.node is ListNode) {
            // For lists, we'd need to implement list-specific hit testing
            // For now, return position 0
            return Position(block.nodeIndex, 0);
          } else if (block.node is TableNode) {
            // For tables, we'd need to implement table-specific hit testing
            // For now, return position 0
            return Position(block.nodeIndex, 0);
          }
        }
      }
    }
    // No exact match found. As a fallback, if we have pages/blocks, find the
    // nearest block vertically and return a best-effort position inside it.
    if (_lastPaginatedPages.isNotEmpty) {
  double bestDist = double.infinity;
  PositionedBlock? bestBlock;
      for (final page in _lastPaginatedPages) {
        final localYInPage = y - page.yOrigin;
        for (final block in page.blocks) {
          final centerY = block.y + block.height / 2;
          final dist = (localYInPage - centerY).abs();
          if (dist < bestDist) {
            bestDist = dist;
            bestBlock = block;
          }
        }
      }

      if (bestBlock != null) {
        final block = bestBlock;
        if (block.node is ParagraphNode) {
          final paragraphNode = block.node as ParagraphNode;
          final layouter = ParagraphLayouter(measureCache);
          final layoutResult = layouter.layout(paragraphNode,
              PageConstraints(width: block.width, height: block.height));

          // Choose the last position in the paragraph as a safe fallback
          var offsetInNode = 0;
          for (var i = 0; i < layoutResult.lines.length; i++) {
            offsetInNode += layoutResult.lines[i].spans.map((s) => s.run.text.length).fold(0, (p, c) => p + c);
          }
          return Position(block.nodeIndex, offsetInNode);
        } else {
          return Position(block.nodeIndex, 0);
        }
      }
    }

    return null;
  }
}