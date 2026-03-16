//收益日曆上方總覽顯示元件
import 'package:flutter/material.dart';

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
    final monthLabel = '${focusedDay.year}/${focusedDay.month}';
    final winColor = stats['winRate'] > 0.6
        ? Colors.red
        : stats['winRate'] < 0.4
            ? Colors.green
            : Colors.white;
    final pnlColor = stats['pnl'] > 0
        ? Colors.red
        : stats['pnl'] < 0
            ? Colors.green
            : Colors.white;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              monthLabel,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                '月損益',
                formatPnL(stats['pnl']),
                pnlColor,
              ),
              _statItem(
                '勝率',
                '${(stats['winRate'] * 100).toStringAsFixed(1)}%',
                winColor,
              ),
              _statItem(
                '交易次數',
                '${stats['trades']}',
                Colors.white,
              ),
              _statItem(
                '連續獲利',
                '🔥$streak',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) { //統計項目UI
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16, //之後改大小參數，且分上下排
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}