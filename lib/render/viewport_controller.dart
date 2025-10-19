class ViewportController {
  double _scrollOffset = 0;

  int get lastVisiblePage {
    // Assuming a fixed page height for now
    final pageHeight = 800;
    return (_scrollOffset / pageHeight).ceil();
  }

  void onScroll(double scrollOffsetPx) {
    _scrollOffset = scrollOffsetPx;
  }
}
