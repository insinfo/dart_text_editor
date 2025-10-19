import 'package:canvas_text_editor/layout/widow_orphan_control.dart';

class PageConstraints {
  final double width;
  final double height;
  final double marginLeft;
  final double marginTop;
  final double marginRight;
  final double marginBottom;
  final WidowOrphanControl widowOrphan;
  final double zoomLevel;

  factory PageConstraints.a4({double marginAllPt = 0.0, WidowOrphanControl widowOrphan = const WidowOrphanControl(), double zoomLevel = 1.0}) {
    const double pageWidthPt = 595.275;
    const double pageHeightPt = 841.89;
    return PageConstraints(
      width: (pageWidthPt - 2 * marginAllPt) * zoomLevel,
      height: (pageHeightPt - 2 * marginAllPt) * zoomLevel,
      marginLeft: marginAllPt * zoomLevel,
      marginTop: marginAllPt * zoomLevel,
      marginRight: marginAllPt * zoomLevel,
      marginBottom: marginAllPt * zoomLevel,
      widowOrphan: widowOrphan,
      zoomLevel: zoomLevel,
    );
  }

  PageConstraints({
    required this.width,
    required this.height,
    this.marginLeft = 0.0,
    this.marginTop = 0.0,
    this.marginRight = 0.0,
    this.marginBottom = 0.0,
    this.widowOrphan = const WidowOrphanControl(),
    this.zoomLevel = 1.0,
  });

  // TODO: Implement PageConstraints properties and methods
}