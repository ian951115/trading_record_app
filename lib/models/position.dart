//庫存模型
class Position { //all
  final String symbol;
  final String name;
  int quantity = 0; //現在還剩幾股
  double totalCost = 0; //尚未賣出的持倉成本
  double realizedPnL =0; //已實現損益（賣出）PnL=Profit and Loss
  double? livePrice; //API拉取的現價（null=尚未取得）
  DateTime? firstBuyDate; //第一次買入日期

  Position({
    required this.symbol,
    required this.name,
  });

  double get avgCost => quantity == 0 ? 0 : totalCost / quantity;

  double get marketValue => (livePrice ?? avgCost) * quantity; //市值
  double get unrealizedPnL => livePrice == null ? 0 : marketValue - totalCost; //未實現損益
  double get unrealizedReturn => //未實現報酬率
       (livePrice == null || totalCost == 0) ? 0 : (unrealizedPnL / totalCost) * 100;

  int get holdingDays { //持有天數計算
    if (firstBuyDate == null || quantity == 0) return 0;
    return DateTime.now().difference(firstBuyDate!).inDays;
  }
}