import 'package:dart_text_editor/core/list_block_node.dart';
import 'package:dart_text_editor/layout/page_constraints.dart';
import 'package:dart_text_editor/layout/font_metrics.dart';
import 'package:dart_text_editor/layout/list_layout_result.dart';

abstract class ListLayouter {
  ListLayoutResult layout(
      ListBlockNode node, PageConstraints box, FontMetrics fm);
}
