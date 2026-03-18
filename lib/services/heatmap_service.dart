//熱力圖顏色計算服務
import 'package:flutter/material.dart';
import 'package:trading_record_app/models/daily_pnl.dart';
import '../utils/heatmap_normalizer.dart';
import '../services/calendar_service.dart';

class HeatmapService {
  static Color dayPnLColor(double pnl, double monthMaxAbs) {
    final n = HeatmapNormalizer.normalize(pnl, monthMaxAbs);

    if (pnl == 0) return Colors.transparent;

    if (pnl > 0) {
      return Colors.red.withValues(alpha: 0.15 + 0.35 * n);
    } else {
      return Colors.green.withValues(alpha: 0.15 + 0.35 * n.abs());
    }
  }

  static Color monthPnLColor(double pnl, double yearMaxAbs) {
    final n = HeatmapNormalizer.normalize(pnl, yearMaxAbs);

    if (n.abs() < 0.08) {
      return Colors.grey.shade100;
    }

    if (n == 0) return Colors.grey.shade200;

    final intensity = 0.2 + 0.6 * n.abs();
    if (n > 0) {
      return Colors.red.withValues(alpha: intensity);
    } else {
      return Colors.green.withValues(alpha: intensity);
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

  static double getMonthMaxAbs(
    Map<DateTime, DailyPnl> map,
    DateTime focused,
  ) {
    double maxVal = 0;

    for (final e in map.entries) {
      if (e.key.year == focused.year &&
          e.key.month == focused.month) {
        if (e.value.pnl.abs() > maxVal) {
          maxVal = e.value.pnl.abs();
        }
      }
    }
    return maxVal;
  }
}