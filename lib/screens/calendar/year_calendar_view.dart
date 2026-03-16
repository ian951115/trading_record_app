//年視圖格子
import 'package:flutter/material.dart';
import 'package:trading_record_app/services/calendar_service.dart';
import '../../services/year_aggregation.dart';
import '../../widgets/calendar/calendar_month_cell.dart';
import '../../widgets/calendar/calendar_stats_card.dart';

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
    final width = MediaQuery.of(context).size.width;
    final ratio = width < 400 ? 0.9 : width < 700 ? 1.05 : 1.2;

    return Column(
      children: [
        _buildHeader(),
        //CalendarStatsCard(
        //  focusedDay: DateTime(currentYear),
        //  stats: ,
        //  streak: 0,
        //  formatPnL: formatPnL,
        //),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: ratio, //長寬比例
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