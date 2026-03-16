//月份格子資訊顯示元件
import 'package:flutter/material.dart';
import '../../services/year_aggregation.dart';
import '../charts/mini_sparkline.dart';

class CalendarMonthCell extends StatelessWidget {
  final int month;
  final YearMonthData? data;
  final double Function(double) heatmapColorValue;
  final Color Function(double) heatmapColor;
  final String Function(double) formatPnL;
  final VoidCallback onTap;

  const CalendarMonthCell({
    super.key,
    required this.month,
    required this.data,
    required this.heatmapColor,
    required this.formatPnL,
    required this.onTap,
    required this.heatmapColorValue,
  });

  @override
  Widget build(BuildContext context) {
    final pnl = data?.totalPnL ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: heatmapColor(pnl),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$month 月', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SizedBox(
              height: 28,
              child: Opacity(
                opacity: 0.75,
                child: MiniSparkline(data: data?.equitySequence ?? []),
              )
            ),
            const Spacer(),
            Text(
              formatPnL(pnl),
              style: const TextStyle(
                fontSize: 13,
                letterSpacing: 0.3,
                fontWeight: FontWeight.bold
              ),
            ),
            if ((data?.totalDividend ?? 0) != 0)
              Text(
                'Div ${formatPnL(data!.totalDividend)}',
                style: const TextStyle(fontSize: 10, color: Colors.blue),
              ),
          ],
        ),
      ),
    );
  }
}