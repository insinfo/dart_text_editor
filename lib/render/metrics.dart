abstract class Metrics {
  double get width;
  double get height;
}

class TextMetrics implements Metrics {
  @override
  final double width;
  @override
  final double height;

  TextMetrics({required this.width, required this.height});
}
