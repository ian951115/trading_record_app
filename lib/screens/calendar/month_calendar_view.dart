//月視圖
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/app_colors.dart';
import '../../models/daily_pnl.dart';
import '../../widgets/calendar/calendar_day_cell.dart';

class MonthCalendarView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, DailyPnl> dailyPnLMap;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;

  const MonthCalendarView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.dailyPnLMap,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 可用總高度扣掉標頭、星期列、margin、border
        const headerHeight = 54.0; //headerPadding vertical:10 × 2 + 標題
        const dowHeight = 36.0;
        const marginV = 20.0; //top 10 + bottom 10
        const borderV = 2.0;
        final available = constraints.maxHeight
            - headerHeight
            - dowHeight
            -marginV
            -borderV
            -24; //加 8px 安全裕度
        final rowHeight = (available / 6).floorToDouble();
      
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E7ED)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: TableCalendar(
              firstDay: DateTime(1961),
              lastDay: DateTime(2100),
              focusedDay: focusedDay,
              rowHeight: rowHeight, //格子高度
              daysOfWeekHeight: 36,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              sixWeekMonthsEnforced: true,

              // ── 標頭樣式 ────────────────────────
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF0F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC5D4EC)),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: Color(0xFF4A6FA5),
                  ),
                ),
                rightChevronIcon: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF0F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC5D4EC)),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF4A6FA5),
                  ),
                ),
                titleTextFormatter: (date, locale) =>
                    '${date.year} 年 ${date.month} 月',
                titleTextStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E)
                ),
                headerPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  border: Border(bottom: BorderSide(color: Color(0xFFE4E7ED))),
                ),
              ),

              // ── 星期列樣式 ──────────────────────
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
                weekendStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.profit,
                ),
                dowTextFormatter: _weekdayFormatter,
              ),

              // ── 日曆格子樣式 ────────────────────
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(),
                todayDecoration: BoxDecoration(),
                outsideDaysVisible: false,
                cellMargin: EdgeInsets.all(3),
              ),

              // ── 自訂格子外觀 ────────────────────
              calendarBuilders: CalendarBuilders(
                selectedBuilder: (context, day, _) => _buildCell(
                  day, isSelected: true,
                ),
                todayBuilder: (context, day, _) => _buildCell(
                  day, isToday: true,
                ),
                defaultBuilder: (context, day, _) => _buildCell(day),
                outsideBuilder: (context, day, _) => const SizedBox.shrink()
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(
    DateTime day, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final key = DateTime(day.year, day.month, day.day);
    final daily = dailyPnLMap[key];
    return CalendarDayCell(
      day: day,
      daily: daily,
      isSelected: isSelected,
      isToday: isToday,
      tradeCount: daily?.trades.length ?? 0,
    );
  }
}

// 星期中文格式
String _weekdayFormatter(DateTime date, dynamic locale) {
  const days = ['一', '二', '三', '四', '五', '六', '日'];
  return days[date.weekday - 1];
}