//年視圖格子
import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../services/calc/pnl_service.dart';
import '../../widgets/calendar/calendar_month_cell.dart';
import '../../widgets/common/year_switcher.dart';

class YearCalendarView extends StatelessWidget {
  final int currentYear;
  final Map<int, YearMonthData> yearData;
  final ValueChanged<int> onYearChanged;
  final void Function(int month) onMonthTap;

  const YearCalendarView({
    super.key,
    required this.currentYear,
    required this.yearData,
    required this.onYearChanged,
    required this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    //年度統計
    double yearPnL = 0;
    int yearTrades = 0;
    int yearWinDays = 0;
    int yearTotalDays = 0;
    int bestMonth = 0;
    double bestMonthPnL = 0;

    for (final entry in yearData.entries) {
      yearPnL += entry.value.totalPnL;
      yearTrades += entry.value.tradeCount;
      yearWinDays += entry.value.winDays;
      yearTotalDays += entry.value.dailyPnLSequence.length;
      if (entry.value.totalPnL > bestMonthPnL) {
        bestMonthPnL = entry.value.totalPnL;
        bestMonth = entry.key;
      }
    }

    final yearWinRate = yearTotalDays == 0
        ? 0.0
        : yearWinDays / yearTotalDays;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -200) {
          onYearChanged(currentYear + 1); //左滑換年
        } else if (details.primaryVelocity! > 200) {
          onYearChanged(currentYear - 1); //右滑
        }
      },
      child: Column(
        children: [
          // ── 年度統計卡片 ──────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3D5A8A), Color(0xFF4A6FA5)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentYear 年度總結',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text( //年度總損益大字
                  yearPnL == 0 ? '—' : AppFmt.pnl(yearPnL),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pnl(yearPnL),
                    letterSpacing: -0.5
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row( //三格統計
                  children: [
                    _YearStat(
                      label: '年度勝率',
                      value: yearTrades == 0
                          ? '—'
                          : '${(yearWinRate * 100).toStringAsFixed(0)}%',
                    ),
                    const _YearDivider(),
                    _YearStat(
                      label: '交易次數',
                      value: yearTrades.toString(),
                    ),
                    const _YearDivider(),
                    _YearStat(
                      label: '最佳月份',
                      value: bestMonth == 0 ? '—' : '$bestMonth 月',
                      valueColor: bestMonth == 0
                          ? Colors.white70
                          : const Color(0xFFFFD6D4),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 年份導航 ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: YearSwitcher(
              year: currentYear,
              onChanged: onYearChanged,
            ),
          ),

          // ── 月份格子 ──────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final data = yearData[month];
                return CalendarMonthCell(
                  month: month,
                  data: data,
                  onTap: () => onMonthTap(month),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _YearStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _YearStat({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white60,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _YearDivider extends StatelessWidget {
  const _YearDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 28,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}