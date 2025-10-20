import 'package:dart_text_editor/util/web_ui.dart';

class EditorTheme {
  final Color fontColor;
  final Color selectionColor;

  final double tableBorderWidthPt;
  final double firstIndent; // first line indent
  final double spacingBefore; // in pt
  final double marginTopPt;
  final double marginRightPt;
  final double listBulletIndentPt;
  final Color cursorColor;

  EditorTheme(
      {this.tableBorderWidthPt = 0.75,
      this.firstIndent = 0.0,
      this.spacingBefore = 0.0,
      this.marginTopPt = 0.0,
      this.marginRightPt = 0.0,
      this.cursorColor = const Color(0xFF000000), // Default black cursor
      this.listBulletIndentPt = 18.0,
      this.fontColor = const Color(0xFF000000),
      this.selectionColor = const Color(0xFFADD8E6)});

  // TODO: Implement EditorTheme properties and methods
}
