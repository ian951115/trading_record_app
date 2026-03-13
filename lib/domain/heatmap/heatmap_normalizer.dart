//heatmap log scaling
import 'dart:math';

class HeatmapNormalizer {
  static double normalize(double value, double maxAbs) {
    if (value == 0 || maxAbs == 0) return 0;

    final sign = value > 0 ? 1 : -1;

    final normalized = log(1 + value.abs()) / log(1 + maxAbs);

    return normalized * sign;
  }
}