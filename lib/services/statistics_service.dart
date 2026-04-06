//統計資料計算服務
import '../models/trade.dart';
import '../models/cash_flow.dart';
import '../services/position_service.dart';
import '../services/chart_service.dart';

// ── 單筆交易紀錄容器 ─────────────────────────────────────────
class TradeRecord {
  final String symbol;
  final String name;
  final DateTime date;
  final double pnl;
  TradeRecord({
    required this.symbol,
    required this.name,
    required this.date,
    required this.pnl,
  });
}

// ── 統計結果容器 ────────────────────────────────
class AllTimeStats {
  final double totalRealizedPnL; //總已實現損益
  final int totalTradingDays; //首次買入至今天數
  final int sellCount; //總賣出筆數（結清次數）
  final double winRate; //勝率 0.0 ~ 1.0

  final TradeRecord? bestTrade; //最大單筆獲利
  final TradeRecord? worstTrade; //最大單筆虧損

  final String? bestReturnSymbol; //最高報酬率個股代碼
  final String? bestReturnName; //最高報酬率個股名稱
  final double bestReturnRate; //報酬率（百分比）
  final bool bestReturnIsOpen; //是否持倉中

  final int maxWinStreak; //最長連勝筆數
  final int maxLossStreak; //最長連敗筆數

  final int longestHoldingDays; //最長持有天數
  final String? longestHoldingSymbol; //對應股票代碼
  final String? longestHoldingName; //對應股票名稱

  final double expectancy; //期望值（元）
  final double maxDrawdownPct; //最大回撤（%，負值）
  const AllTimeStats({
    required this.totalRealizedPnL,
    required this.totalTradingDays,
    required this.sellCount,
    required this.winRate,
    this.bestTrade,
    this.worstTrade,
    this.bestReturnSymbol,
    this.bestReturnName,
    required this.bestReturnRate,
    required this.bestReturnIsOpen,
    required this.maxWinStreak,
    required this.maxLossStreak,
    required this.longestHoldingDays,
    this.longestHoldingSymbol,
    this.longestHoldingName,
    required this.expectancy,
    required this.maxDrawdownPct,
  });

  //資料不足時的空結果
  static const empty = AllTimeStats(
    totalRealizedPnL: 0, totalTradingDays: 0, sellCount: 0,
    winRate: 0, bestReturnRate: 0, bestReturnIsOpen: false,
    maxWinStreak: 0, maxLossStreak: 0, longestHoldingDays: 0,
    expectancy: 0, maxDrawdownPct: 0,
  );
}

// ── 主服務 ──────────────────────────────────────
class StatisticsService {
  static AllTimeStats calculate({
    required List<Trade> trades,
    required List<CashFlow> cashFlows,
  }) {
    if (trades.isEmpty) return AllTimeStats.empty;

    //用既有position_service算出持倉和損益Map
    final result = buildPositions(trades);
    final positions = result.positions;
    final pnlMap = result.tradePnLMap;

    //1.賣出紀錄（時間排序，用於連勝/連敗）
    final sells = trades
        .where((t) => t.type == TradeType.sell)
        .toList()..sort((a, b) => a.date.compareTo(b.date));

    if (sells.isEmpty) {
      //只有買入，無賣出紀錄時回傳部分統計
      final firstBuy = trades
          .map((t) => t.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final days = DateTime.now().difference(firstBuy).inDays;
      return AllTimeStats(
        totalRealizedPnL: 0,
        totalTradingDays: days,
        sellCount: 0,
        winRate: 0,
        bestReturnRate: 0,
        bestReturnIsOpen: false,
        maxWinStreak: 0,
        maxLossStreak: 0,
        longestHoldingDays: positions.isEmpty ? 0
            : positions.map((p) => p.holdingDays)
                  .reduce((a, b) => a > b ? a : b),
        expectancy: 0,
        maxDrawdownPct: 0,
      );
    }

    //2.總已實現損益
    final totalPnL = positions.fold(0.0, (s, p) => s + p.realizedPnL);

    //3.首次買入日 → 交易天數
    final firstBuyDate = trades
        .map((t) => t.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final tradingDays = DateTime.now().difference(firstBuyDate).inDays;

    //4.勝率
    int wins = 0;
    for (final t in sells) {
      if ((pnlMap[t.id] ?? 0) > 0) wins++;
    }
    final winRate = sells.isEmpty ? 0.0 : wins / sells.length;

    //5.最佳/最差單筆
    TradeRecord? best, worst;
    for (final t in sells) {
      final pnl = pnlMap[t.id] ?? 0.0;
      final rec = TradeRecord(
        symbol: t.symbol, name: t.name, date: t.date, pnl: pnl);
      if (best == null || pnl > best.pnl) best = rec;
      if (worst == null || pnl < worst.pnl) worst = rec;
    }

    //6.最高報酬率個股（含持倉中：用未實現報酬率）
    String? bestSym, bestName;
    double bestRate = 0;
    bool bestIsOpen = false;
    for (final pos in positions) {
      final rate = pos.unrealizedReturn;
      if (rate > bestRate) {
        bestRate = rate;
        bestSym = pos.symbol;
        bestName = pos.name;
        bestIsOpen = pos.quantity > 0;
      }
    }

    //7.連勝/連敗
    int maxWin = 0, maxLoss = 0, curWin = 0, curLoss = 0;
    for (final t in sells) {
      final pnl = pnlMap[t.id] ?? 0.0;
      if (pnl > 0) {
        curWin++;
        curLoss = 0;
        if (curWin > maxWin) maxWin = curWin;
      } else {
        curLoss++;
        curWin = 0;
        if (curLoss > maxLoss) maxLoss = curLoss;
      }
    }

    //8.最長持有個股
    int longestDays = 0;
    String? longestSym, longestName;
    for (final pos in positions) {
      if (pos.holdingDays > longestDays) {
        longestDays = pos.holdingDays;
        longestSym = pos.symbol;
        longestName = pos.name;
      }
    }

    //9.期望值 = winRate × avgWin − (1 − winRate) × avgLoss
    double sumWin = 0, sumLoss = 0;
    int cntWin = 0, cntLoss = 0;
    for (final t in sells) {
      final pnl = pnlMap[t.id] ?? 0.0;
      if (pnl > 0) {
        sumWin += pnl;
        cntWin++;
      } else {
        sumLoss += pnl.abs();
        cntLoss++;
      }
    }
    final avgWin = cntWin > 0 ? sumWin / cntWin : 0.0; //每次賺賺多少
    final avgLoss = cntLoss > 0 ? sumLoss / cntLoss : 0.0; //每次輸輸多少
    final expectancy = winRate * avgWin - (1 - winRate) * avgLoss;

    //10.最大回撤（從 ChartService 時間序列計算）
    double maxDD = 0;
    try {
      final history = ChartService.buildAssetHistory(
        trades: trades, cashFlows: cashFlows);
      double peak = 0;
      for (final pt in history) {
        if (pt.totalAsset > peak) peak = pt.totalAsset; //找高點
        if (peak > 0) {
          final dd = (pt.totalAsset - peak) / peak * 100; //算回測
          if (dd < maxDD) maxDD = dd;
        }
      }
    } catch (_) {
      //ChartService 失敗時最大回撤留 0
    }

    return AllTimeStats(
      totalRealizedPnL: totalPnL,
      totalTradingDays: tradingDays,
      sellCount: sells.length,
      winRate: winRate,
      bestTrade: best,
      worstTrade: worst,
      bestReturnSymbol: bestSym,
      bestReturnName: bestName,
      bestReturnRate: bestRate,
      bestReturnIsOpen: bestIsOpen,
      maxWinStreak: maxWin,
      maxLossStreak: maxLoss,
      longestHoldingDays: longestDays,
      longestHoldingSymbol: longestSym,
      longestHoldingName: longestName,
      expectancy: expectancy,
      maxDrawdownPct: maxDD,
    );
  }
}

