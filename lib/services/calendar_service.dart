//日曆的交易聚合計算服務
import '../models/trade.dart';
import '../models/daily_pnl.dart';

// 每月彙總資料（有型別，比 Map<String,dynamic> 安全）
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

class CalendarService {
  static Map<DateTime, DailyPnl> groupTradesByDay(
    List<Trade> trades,
    Map<String, double> tradePnLMap,
  ) {
    final Map<DateTime, List<Trade>> grouped = {}; //日期對交易

    for (var trade in trades) { //先把每筆交易一時間分類
      final date = DateTime( //讀取交易日期
        trade.date.year,
        trade.date.month,
        trade.date.day,
      );

      if (!grouped.containsKey(date)) { //看map裡有沒有該日期
        grouped[date] = []; //無則新增空間
      }
      grouped[date]!.add(trade); //加到該日期
    }

    final Map<DateTime, DailyPnl> result = {}; //日期對收益

    grouped.forEach((date, trades) { //把某天的收益加起來
      double pnl = 0;

      for (var t in trades) {
        pnl += tradePnLMap[t.id] ?? 0; //用tradePnLMap查已實現損益，找不到就用0
      }

      result[date] = DailyPnl(
        date: date,
        pnl: pnl,
        trades: trades,
        dividend: 0,
      );
    });

    return result;
  }

  static Map<String, dynamic> calculateMonthStats( //取得月份資料
    Map<DateTime, DailyPnl> dailyPnLMap,
    DateTime focusedDay,
  ) {
    double totalPnL = 0;
    int winDays = 0;
    int tradeCount = 0;

    for (final entry in dailyPnLMap.entries) {
      final day = entry.key;
      final daily = entry.value;

      if (day.year == focusedDay.year && day.month == focusedDay.month) {
        totalPnL += daily.pnl;
        if (daily.pnl > 0) winDays++;
        tradeCount += daily.trades.length;
      }
    }

    final totalDays = dailyPnLMap.entries.where((e) =>
        e.key.year == focusedDay.year &&
        e.key.month == focusedDay.month).length;

    double winRate = totalDays == 0 ? 0 : winDays / totalDays;

    return {
      'pnl': totalPnL,
      'winRate': winRate,
      'trades': tradeCount,
    };
  }

  static int calculateWinStreak( //連勝計算
    Map<DateTime, DailyPnl> dailyPnLMap,
    DateTime focusedDay,
  ) {
    final entries = dailyPnLMap.entries
        .where((e) =>
            e.key.year == focusedDay.year &&
            e.key.month == focusedDay.month)
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    int streak = 0;
    for (final entry in entries) {
      if (entry.value.pnl > 0) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }




  static Map<int, YearMonthData> calculateYearlyData( //取得年份資料
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
}