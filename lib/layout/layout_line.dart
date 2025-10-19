import '../core/text_run.dart';

class LayoutSpan {
  final TextRun run;
  final int
      startInNode; // Absolute offset of this span's text within the paragraph node
  final int
      endInNode; // Absolute end offset of this span's text within the paragraph node
  final bool
      hidden; // Whether this span should be rendered (false) or just counted for offsets (true)

  LayoutSpan(this.run, this.startInNode, this.endInNode, {this.hidden = false});
  LayoutSpan.hidden(TextRun run, int s, int e) : this(run, s, e, hidden: true);
}

class LayoutLine {
  final List<LayoutSpan> spans; // Changed from runs to spans
  final double height;
  final double width;

  LayoutLine(this.spans, this.height, this.width); // Changed constructor
}
