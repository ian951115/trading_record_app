//年視圖格子的資料核心
import 'package:trading_record_app/models/daily_pnl.dart';

class YearMonthData {
  final int month;
  final double totalPnL;
  final int tradeCount;
  final int winDays;
  final List<double> dailyPnLSequence;
  final List<double> equitySequence;
  final double totalDividend;

  const YearMonthData({
    required this.month,
    required this.totalPnL,
    required this.tradeCount,
    required this.winDays,
    required this.dailyPnLSequence,
    required this.equitySequence,
    required this.totalDividend,
  });

  double get winRate =>
      dailyPnLSequence.isEmpty ? 0 : winDays / dailyPnLSequence.length;
}

Map<int, YearMonthData> calculateYearlyData(
  Map<DateTime, DailyPnl> dailyMap, //時間對每日收益
  int year,
) {
  final Map<int, List<DailyPnl>> monthBuckets = {}; //月份對該月所有每日收益

  for (final entry in dailyMap.entries) {
    final date = entry.key;
    final daily = entry.value;

    if (date.year != year) continue; //看傳進來的資料是不是要的年份

    monthBuckets.putIfAbsent(date.month, () => []); //為月份開一個空間
    monthBuckets[date.month]!.add(daily); //加入月份資料
  }

  final Map<int, YearMonthData> result = {}; //月份對每月資料

  for (final entry in monthBuckets.entries) {
    final month = entry.key;
    final dailies = entry.value;

    double totalPnL = 0;
    int tradeCount = 0;
    int winDays = 0;
    List<double> pnlSeq = [];
    List<double> equitySeq = [];
    double equity = 0;
    double dividend = 0;

    for (final d in dailies) {
      totalPnL += d.pnl;
      tradeCount += d.trades.length;

      pnlSeq.add(d.pnl);

      equity += d.pnl;
      equitySeq.add(equity);
      dividend += d.dividend;

      if (d.pnl > 0) winDays++;
    }

    result[month] = YearMonthData(
      month: month,
      totalPnL: totalPnL,
      tradeCount: tradeCount,
      winDays: winDays,
      dailyPnLSequence: pnlSeq,
      equitySequence: equitySeq,
      totalDividend: dividend,
    );
  }
  return result;
}