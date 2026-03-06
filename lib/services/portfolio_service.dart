//計算服務
import '../models/trade.dart';
import '../models/position.dart';
import '../models/cash_flow.dart';

class PortfolioService {
  //計算現金餘額
  static double calculateCash({
    required List<Trade> trades,
    required List<CashFlow> cashFlows,
  }) {
    final tradeImpact = trades.fold(
      0.0,
      (sum, trade) => sum + trade.netAmount,
    );

    final cashImpact = cashFlows.fold(
      0.0,
      (sum, flow) => sum + flow.netAmount,
    );

    return tradeImpact + cashImpact;
  }

  //計算持倉市值
  static double calculateMarketValue(
    List<Position> positions,
  ) {
    return positions.fold(
      0.0,
      (sum, p) => sum + p.marketValue,
    );
  }

  //計算總資產
  static double calculateTotalAsset({
    required double cash,
    required List<Position> positions,
  }) {
    final marketValue = calculateMarketValue(positions);
    return cash + marketValue;
  }

  //計算已實現損益
  static double calculateTotalRealizedPnL(
    List<Position> positions,
  ) {
    return positions.fold(
      0.0,
      (sum, p) => sum + p.realizedPnL,
    );
  }

  //計算未實現損益
  static double calculateTotalUnrealizedPnL(
    List<Position> positions,
  ) {
    return positions.fold(
      0.0,
      (sum, p) => sum + p.unrealizedPnL,
    );
  }
}