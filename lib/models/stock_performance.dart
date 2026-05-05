//個股績效模型
class StockPerformance {
  final String symbol;
  final String name;
  final double totalRealizedPnL; //已實現總損益
  final int totalBuyCount; // 買入次數
  final int totalSellCount; // 賣出次數
  final int winCount; // 獲利的賣出次數
  final double totalBuyAmount; // 總買入金額
  final double totalSellAmount; // 總賣出金額
  final bool isOpen; // 是否還持有
  final int? holdingDays; // 持有天數（已平倉才有）
  final double totalFee; // 總費用（買手續費 + 賣手續費 + 交易稅）

  StockPerformance({
    required this.symbol,
    required this.name,
    required this.totalRealizedPnL,
    required this.totalBuyCount,
    required this.totalSellCount,
    required this.winCount,
    required this.totalBuyAmount,
    required this.totalSellAmount,
    required this.isOpen,
    this.holdingDays,
    required this.totalFee,
  });

  double get winRate =>
      totalSellCount == 0 ? 0 : winCount / totalSellCount;
}