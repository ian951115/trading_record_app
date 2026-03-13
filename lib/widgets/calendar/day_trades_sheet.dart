//每日交易表單的顯示元件
import 'package:flutter/material.dart';
import '../../models/trade.dart';

class DayTradesSheet extends StatelessWidget {
  final DateTime date;
  final List<Trade> trades;
  final double pnl;
  final ScrollController scrollController;

  const DayTradesSheet({
    required this.date,
    required this.trades,
    required this.pnl,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),        
      children: [
        Text(
          '${date.year}-${date.month}-${date.day}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '當日損益: ${pnl.toStringAsFixed(0)}',
          style: TextStyle(
            color: pnl >= 0 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (trades.isEmpty)
          const Text('沒有交易'),
        
        ...trades.map((t) {
          return ListTile(
            title: Text(t.symbol),
            subtitle: Text(t.type.name),
            trailing: Text(
              t.netAmount.toStringAsFixed(0),
              style: TextStyle(
                color: t.netAmount >= 0
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          );
        }),
      ],
    );
  }
}