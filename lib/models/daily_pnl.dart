//每日損益模型
import '../models/trade.dart';

class DailyPnl {
  final DateTime date;
  final double pnl;
  final List<Trade> trades;
  final double dividend;

  DailyPnl({
    required this.date,
    required this.pnl,
    required this.trades,
    this.dividend = 0,
  });
}