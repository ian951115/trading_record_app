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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12,vertical: 4),
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
                stats['pnl'] >=0 ? Colors.red : Colors.green,
              ),
              _statItem(
                '勝率',
                '${(stats['winRate'] * 100).toStringAsFixed(1)}%',
                Colors.white,
              ),
              _statItem(
                '交易',
                '${stats['trades']}',
                Colors.white,
              ),
              _statItem(
                '連勝',
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}