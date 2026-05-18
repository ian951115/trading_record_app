//收益日曆上方統計卡片元件
import 'package:flutter/material.dart';
import 'package:trading_record_app/core/app_colors.dart';
import '../../core/formatters.dart';


class CalendarStatsCard extends StatelessWidget {
  final DateTime focusedDay;
  final Map stats;
  final int streak;
  final String Function(double) formatPnL;

  const CalendarStatsCard({
    super.key,
    required this.focusedDay,
    required this.stats,
    required this.streak,
    required this.formatPnL,
  });
  
  @override
  Widget build(BuildContext context) { //統計卡 Widget
    final pnl = (stats['pnl'] as double?) ?? 0.0;
    final winRate = (stats['winRate'] as double?) ?? 0.0;
    final trades = (stats['trades'] as int?) ?? 0;

    final pnlColor = AppColors.pnl(pnl);
    final winColor = winRate > 0.6
        ? const Color(0xFFFFD6D4)
        : winRate < 0.4
            ? const Color(0xFFB8F0D0)
            : Colors.white;

    return Container(
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
          Text( //年月標題
            '${focusedDay.year} 年 ${focusedDay.month} 月',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row( //四格統計
            children: [
              _StatItem(
                label: '月損益',
                value: pnl == 0
                    ? '—'
                    : AppFmt.pnl(pnl),
                valueColor: pnlColor,
              ),
              const _Divider(),
              _StatItem(
                label: '勝率',
                value: trades == 0
                    ? '—'
                    : '${(winRate * 100).toStringAsFixed(1)}%',
                valueColor: winColor,
              ),
              const _Divider(),
              _StatItem(
                label: '交易次數',
                value: trades.toString(),
              ),
              _StatItem(
                label: '連續獲利',
                value: streak > 0 ? '🔥$streak' : '—',
                valueColor: streak > 0
                    ? const Color(0xFFFFD08A)
                    : Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget { //統計項目UI
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({
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
              letterSpacing: 0.5
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}