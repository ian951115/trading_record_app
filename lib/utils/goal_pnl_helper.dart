//已實現損益計算
import '../models/trade.dart';
import '../services/position_service.dart';


class GoalPnlHelper {
  // 計算指定日期範圍與標的的已實現損益
  static double calc({
    required List<Trade> trades,
    required DateTime startDate,
    required DateTime endDate,
    String? stockSymbol, //null = 計算總損益
  }) {
    // 1. 篩選 sell 交易，且日期在範圍內
    final sells = trades.where((t) =>
      t.type == TradeType.sell &&
      !t.date.isBefore(startDate) &&
      !t.date.isAfter(endDate) &&
      (stockSymbol == null || t.symbol == stockSymbol),
    ).toList();
 
    if (sells.isEmpty) return 0;
 
    // 2. 用 PositionService 取 P&L map
    final result = buildPositions(trades);
    final pnlMap = result.tradePnLMap;
 
    // 3. 累加
    return sells.fold(0.0, (sum, t) => sum + (pnlMap[t.id] ?? 0));
  }
}
