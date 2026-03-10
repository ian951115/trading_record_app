//每日損益模型
import '../models/trade.dart';

class DailyPnl {
  final DateTime date;
  final double pnl;
  final List<Trade> trades;

  DailyPnl({
    required this.date,
    required this.pnl,
    required this.trades,
  });
}