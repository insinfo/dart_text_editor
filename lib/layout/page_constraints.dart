// Arquivo: lib/layout/page_constraints.dart
import 'package:dart_text_editor/layout/widow_orphan_control.dart';

class PageConstraints {
  final double width;
  final double height;
  final double marginLeft;
  final double marginTop;
  final double marginRight;
  final double marginBottom;
  final WidowOrphanControl widowOrphan;
  final double zoomLevel;

  factory PageConstraints.a4(
      {double marginAllPt = 0.0, // Mantenha o parâmetro
      WidowOrphanControl widowOrphan = const WidowOrphanControl(),
      double zoomLevel = 1.0}) {
    // --- MUDANÇA PARA TESTE: Ignorar marginAllPt ---
    print(
        "[PageConstraints.a4] FOR TEST: IGNORING marginAllPt, using ZERO margins.");
    marginAllPt = 0; // FORÇA MARGENS ZERO PARA TESTE
    // --- FIM DA MUDANÇA ---

    const double pageWidthPt = 595.275;
    const double pageHeightPt = 841.89;
    // Cálculos agora assumem margens zero
    final double marginLeftPx = marginAllPt * zoomLevel; // Será 0
    final double marginTopPx = marginAllPt * zoomLevel; // Será 0
    final double marginRightPx = marginAllPt * zoomLevel; // Será 0
    final double marginBottomPx = marginAllPt * zoomLevel; // Será 0
    // Largura e Altura do conteúdo agora são a largura/altura total da página (zoom aplicado)
    final double contentWidthPx = (pageWidthPt * zoomLevel);
    final double contentHeightPx = (pageHeightPt * zoomLevel);

    return PageConstraints(
      width: contentWidthPx.clamp(0.0, double.infinity),
      height: contentHeightPx.clamp(0.0, double.infinity),
      marginLeft: marginLeftPx, // Será 0
      marginTop: marginTopPx, // Será 0
      marginRight: marginRightPx, // Será 0
      marginBottom: marginBottomPx, // Será 0
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

  // --- INÍCIO DA CORREÇÃO ---
  // Adiciona o método copyWith
  PageConstraints copyWith({
    double? width,
    double? height,
    double? marginLeft,
    double? marginTop,
    double? marginRight,
    double? marginBottom,
    WidowOrphanControl? widowOrphan,
    double? zoomLevel,
  }) {
    return PageConstraints(
      width: width ?? this.width,
      height: height ?? this.height,
      marginLeft: marginLeft ?? this.marginLeft,
      marginTop: marginTop ?? this.marginTop,
      marginRight: marginRight ?? this.marginRight,
      marginBottom: marginBottom ?? this.marginBottom,
      widowOrphan: widowOrphan ?? this.widowOrphan,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
  // --- FIM DA CORREÇÃO ---

  // TODO: Implement PageConstraints properties and methods
}
