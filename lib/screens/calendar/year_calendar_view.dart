//年視圖
import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../services/calc/pnl_service.dart';
import '../../widgets/calendar/calendar_month_cell.dart';
import '../../widgets/common/year_switcher.dart';
import '../../widgets/common/hero_card.dart';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: HeroCard(
              title: '$currentYear 累計損益',
              mainValue: Text(
                yearPnL == 0 ? '—' : AppFmt.pnl(yearPnL),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pnl(yearPnL),
                  letterSpacing: -0.5
                ),
              ),
              stats: [
                HeroStat(
                  label: '年度勝率',
                  value: yearTrades == 0
                      ? '—'
                      : '${(yearWinRate * 100).toStringAsFixed(1)}%',
                ),
                HeroStat(
                  label: '交易次數',
                  value: yearTrades.toString(),
                ),
                HeroStat(
                  label: '最佳月份',
                  value: bestMonth == 0 ? '—' : '$bestMonth 月',
                  valueColor: bestMonth == 0
                      ? Colors.white70
                      : const Color(0xFFFFD6D4),
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