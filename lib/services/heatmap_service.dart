//熱力圖顏色計算服務
import 'package:flutter/material.dart';
import '../utils/heatmap_normalizer.dart';
import 'year_aggregation.dart';

class HeatmapService {
  static Color dayPnLColor(double pnl, {bool reverse = false}) {
    if (pnl == 0) return Colors.transparent;

    const maxValue = 200000;
    double intensity = (pnl.abs() / maxValue).clamp(0.05, 0.5);

    if (pnl > 0) {
      return (reverse ? Colors.green : Colors.red)
          .withValues(alpha: intensity);
    } else {
      return (reverse ? Colors.red : Colors.green)
          .withValues(alpha: intensity);
    }
  }

  static Color monthPnLColor(double pnl, double yearMaxAbs) {
    final n = HeatmapNormalizer.normalize(pnl, yearMaxAbs);

    if (n == 0) return Colors.grey.shade200;

    if (n > 0) {
      return Colors.red.withValues(alpha: 0.15 + 0.35 * n);
    } else {
      return Colors.green.withValues(alpha: 0.15 + 0.35 * n.abs());
    }
  }

  static double getYearMaxAbs(Map<int, YearMonthData> yearData) {
    double maxVal = 0;

    for (final m in yearData.values) {
      if (m.totalPnL.abs() > maxVal) {
        maxVal = m.totalPnL.abs();
      }
    }

    return maxVal;
  }
}