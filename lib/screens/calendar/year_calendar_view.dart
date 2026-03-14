//年視圖格子
import 'package:flutter/material.dart';
import '../../services/year_aggregation.dart';
import '../../widgets/calendar/calendar_month_cell.dart';

class YearCalendarView extends StatelessWidget {
  final int currentYear;
  final Map<int, YearMonthData> yearData;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;
  final void Function(int month) onMonthTap;
  final Color Function(double) heatmapColor;
  final String Function(double) formatPnL;

  const YearCalendarView({
    super.key,
    required this.currentYear,
    required this.yearData,
    required this.onPrevYear,
    required this.onNextYear,
    required this.onMonthTap,
    required this.heatmapColor,
    required this.formatPnL,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final data = yearData[month];

              return CalendarMonthCell(
                month: month,
                data: data,
                heatmapColor: heatmapColor,
                formatPnL: formatPnL,
                heatmapColorValue: (_) => 0,
                onTap: () => onMonthTap(month),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrevYear),
          Text('$currentYear 年',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNextYear),
        ],
      ),
    );
  }
}