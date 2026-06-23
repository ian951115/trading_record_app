//年視圖格子
import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../services/calc/pnl_service.dart';
import '../../widgets/calendar/calendar_month_cell.dart';

class YearCalendarView extends StatelessWidget {
  final int currentYear;
  final Map<int, YearMonthData> yearData;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;
  final void Function(int month) onMonthTap;

  const YearCalendarView({
    super.key,
    required this.currentYear,
    required this.yearData,
    required this.onPrevYear,
    required this.onNextYear,
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
          onNextYear(); //左滑換年
        } else if (details.primaryVelocity! > 200) {
          onPrevYear(); //右滑
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                _NavBtn(onTap: onPrevYear, icon: Icons.chevron_left),
                Expanded(
                  child: Text(
                    '$currentYear 年',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F2E),
                    ),
                  ),
                ),
                _NavBtn(onTap: onNextYear, icon: Icons.chevron_right),
              ],
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

class _NavBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _NavBtn({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFEBF0F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC5D4EC)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF4A6FA5)),
      ),
    );
  }
}