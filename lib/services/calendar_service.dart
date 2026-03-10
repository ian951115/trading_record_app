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
      );
    });

    return result;
  }
}