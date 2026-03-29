//圖表相關計算服務
import '../models/trade.dart';
import '../models/cash_flow.dart';
import '../models/position.dart';
import '../services/portfolio_service.dart';
import '../services/position_service.dart';
import '../services/calendar_service.dart';

class ChartService {

  //總資產變化曲線資料
  // 回傳每個有交易或入金的日期對應的總資產
  static List<AssetDataPoint> buildAssetHistory({
    required List<Trade> trades,
    required List<CashFlow> cashFlows,
  }) {
    // 收集所有有意義的日期
    final allDates = <DateTime>{};
    for (final t in trades) {
      allDates.add(DateTime(t.date.year, t.date.month, t.date.day));
    }
    for (final f in cashFlows) {
      allDates.add(DateTime(f.date.year, f.date.month, f.date.day));
    }

    final sortedDates = allDates.toList()..sort();
    final result = <AssetDataPoint>[];

    for (final date in sortedDates) {
      // 只算截至該日期的交易和入金
      final tradesUpTo = trades.where((t) =>
        !t.date.isAfter(date)).toList();
      final flowsUpTo = cashFlows.where((f) =>
        !f.date.isAfter(date)).toList();

      final posResult = buildPositions(tradesUpTo);
      final cash = PortfolioService.calculateCash(
        trades: tradesUpTo, cashFlows: flowsUpTo);
      final marketValue = PortfolioService.calculateMarketValue(
        posResult.positions);

      result.add(AssetDataPoint(
        date: date,
        totalAsset: cash + marketValue,
        cash: cash,
        marketValue: marketValue,
      ));
    }
    return result;
  }

  //每月損益長條圖資料
  static Map<int, double> buildMonthlyPnL({
    required List<Trade> trades,
    required int year,
  }) {
    final result = <int, double>{};
    final posResult = buildPositions(trades);
    final dailyMap = CalendarService.groupTradesByDay(
      trades, posResult.tradePnLMap);
    final yearData = CalendarService.calculateYearlyData(
      dailyMap, year);

    for (final entry in yearData.entries) {
      result[entry.key] = entry.value.totalPnL;
    }
    return result;
  }

  //持股佔比圓餅圖資料
  static List<HoldingShare> buildHoldingShares(
    List<Position> openPositions,
  ) {
    final total = openPositions.fold(
      0.0, (s, p) => s + p.marketValue);
    if (total == 0) return [];

    return openPositions.map((p) => HoldingShare(
      symbol: p.symbol,
      name: p.name,
      marketValue: p.marketValue,
      percentage: p.marketValue / total * 100,
    )).toList()
    ..sort((a,b) =>
      b.marketValue.compareTo(a.marketValue)); //依市值排序
  }

  //策略績效長條圖資料
  static List<StrategyPerf> buildStrategyPerf(
    List<Trade> trades,
    Map<String, double> tradePnLMap,
  ) {
    final map = <String, _StratAccum>{};

    for (final trade in trades) {
      for (final tag in trade.tags) {
        map.putIfAbsent(tag, () => _StratAccum(name: tag)); //新增特定標籤累加器
        final acc = map[tag]!;
        acc.tradeCount++;
        final pnl = tradePnLMap[trade.id] ?? 0;
        acc.totalPnL += pnl;
        if (pnl > 0) acc.winCount++;
        if (trade.type == TradeType.sell) acc.sellCount++;
      }
    }

    return map.values.map((a) => StrategyPerf(
      name: a.name,
      totalPnL: a.totalPnL,
      tradeCount: a.tradeCount,
      winRate: a.sellCount == 0
          ? 0 : a.winCount / a.sellCount,
    )).toList()
    ..sort((a,b) =>
      b.totalPnL.compareTo(a.totalPnL));
  }
}

// ── 資料模型 ──
class AssetDataPoint { //資產資料模型
  final DateTime date;
  final double totalAsset;
  final double cash;
  final double marketValue;
  const AssetDataPoint({
    required this.date,
    required this.totalAsset,
    required this.cash,
    required this.marketValue,
  });
}

class HoldingShare { //持股市值與占比模型
  final String symbol;
  final String name;
  final double marketValue;
  final double percentage;
  const HoldingShare({
    required this.symbol,
    required this.name,
    required this.marketValue,
    required this.percentage,
  });
}

class StrategyPerf { //個股績效模型
  final String name;
  final double totalPnL;
  final int tradeCount;
  final double winRate;
  const StrategyPerf({
    required this.name,
    required this.totalPnL,
    required this.tradeCount,
    required this.winRate,
  });
}

class _StratAccum { //累加器
  final String name;
  double totalPnL = 0;
  int tradeCount = 0;
  int winCount = 0;
  int sellCount = 0;
  _StratAccum({required this.name});
}
