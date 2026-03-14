//日曆的交易聚合計算服務
import '../models/trade.dart';
import '../models/daily_pnl.dart';

class CalendarService {
  static Map<DateTime, DailyPnl> groupTradesByDay(List<Trade> trades) {
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
        pnl += t.netAmount;
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
}