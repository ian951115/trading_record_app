//月視圖格子
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/daily_pnl.dart';
import '../../widgets/calendar/calendar_day_cell.dart';

class MonthCalendarView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, DailyPnl> dailyPnLMap;

  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;

  final String Function(double) formatPnL;
  final Color Function(double) heatmapColor;

  const MonthCalendarView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.dailyPnLMap,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.formatPnL,
    required this.heatmapColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height; //螢幕高度(防overflow)
    final rowHeight = screenHeight * 0.085;

    return TableCalendar(
      firstDay: DateTime(1961),
      lastDay: DateTime(2100),
      focusedDay: focusedDay,
      rowHeight: rowHeight, //格子高度
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: const CalendarStyle(
        selectedDecoration: BoxDecoration(),
        todayDecoration: BoxDecoration(),
        outsideDaysVisible: false,
      ),
      calendarBuilders: CalendarBuilders(
        selectedBuilder: (context, day, _) {
          final key = DateTime(day.year, day.month, day.day);
          final daily = dailyPnLMap[key];
          return CalendarDayCell(
            day: day,
            daily: daily,
            isSelected: true,
            formatPnL: formatPnL,
            heatmapColor: heatmapColor,
          );
        },
        todayBuilder: (context, day, _) {
          final key = DateTime(day.year, day.month, day.day);
          final daily = dailyPnLMap[key];
          return CalendarDayCell(
            day: day,
            daily: daily,
            isToday: true,
            formatPnL: formatPnL,
            heatmapColor: heatmapColor,
          );
        },
        defaultBuilder: (context, day, _) {
          final key = DateTime(day.year, day.month, day.day);
          final daily = dailyPnLMap[key];
          return CalendarDayCell(
            day: day,
            daily: daily,
            formatPnL: formatPnL,
            heatmapColor: heatmapColor,
          );
        },
      ),
    );
  }
}