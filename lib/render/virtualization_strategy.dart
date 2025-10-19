class VirtualizationStrategy {
  List<int> getVisiblePages(double scrollOffset, double viewportHeight, double pageHeight) {
    final firstVisiblePage = (scrollOffset / pageHeight).floor();
    final lastVisiblePage = ((scrollOffset + viewportHeight) / pageHeight).ceil();
    return List.generate(lastVisiblePage - firstVisiblePage + 1, (i) => firstVisiblePage + i);
  }
}