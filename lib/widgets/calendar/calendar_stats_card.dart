//收益日曆上方統計卡片元件
import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../common/hero_card.dart';

class CalendarStatsCard extends StatelessWidget {
  final DateTime focusedDay;
  final Map stats;
  final int streak;

  const CalendarStatsCard({
    super.key,
    required this.focusedDay,
    required this.stats,
    required this.streak,
  });
  
  @override
  Widget build(BuildContext context) { //統計卡 Widget
    final pnl = (stats['pnl'] as double?) ?? 0.0;
    final winRate = (stats['winRate'] as double?) ?? 0.0;
    final trades = (stats['trades'] as int?) ?? 0;

    final winColor = winRate > 0.6
        ? const Color(0xFFFFD6D4)
        : winRate < 0.4
            ? const Color(0xFFB8F0D0)
            : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: HeroCard(
        title: '${focusedDay.year} 年 ${focusedDay.month} 月',
        mainValue: Text(
          pnl == 0 ? '—' : AppFmt.pnl(pnl),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: pnl == 0 ? Colors.white70 : Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        stats: [
          HeroStat(
            label: '勝率',
            value: trades == 0
                ? '—'
                : '${(winRate * 100).toStringAsFixed(1)}%',
            valueColor: winColor,
          ),
          HeroStat(
            label: '交易次數',
            value: trades.toString(),
          ),
          HeroStat(
            label: '連續獲利',
            value: streak > 0 ? '🔥$streak' : '—',
            valueColor: streak > 0
                ? const Color(0xFFFFD08A)
                : Colors.white70,
          ),
        ],
      ),
    );
  }
}