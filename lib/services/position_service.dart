//商品相關計算服務
import '../models/trade.dart';
import '../models/position.dart';
import '../models/stock_performance.dart';
import '../models/dividend.dart';

class PositionResult { //buildPositions的回傳結果
  final List<Position> positions;
  final Map<String, double> tradePnLMap; //key=trade.id,value=該筆賣出的已實現損益

  const PositionResult({
    required this.positions,
    required this.tradePnLMap,
  });
}

class BuyLot { //某一次買進的剩餘股數與價格
  int quantity;
  double costPerShare;

  BuyLot({
    required this.quantity,
    required this.costPerShare,
  });
}

//庫存計算服務
PositionResult buildPositions(
  List<Trade> trades, {
  List<Dividend> dividends = const [],
}) { //FIFO主函式
  final Map<String, Position> positionMap = {}; //存每檔股票的最終庫存
  final Map<String, List<BuyLot>> buyLotMap = {}; //存FIFO用的買進批次
  final Map<String, double> tradePnLMap = {};

  final sortedTrades = [...trades] //時間排序：舊的先算（FIFO）
    ..sort((a, b) => a.date.compareTo(b.date));

  for (final trade in sortedTrades) {
    final key = trade.symbol;

    positionMap.putIfAbsent( //檢查有無該商品，無則建立該商品空間
      key,
      () => Position(symbol: trade.symbol, name: trade.name),
    );
    buyLotMap.putIfAbsent(key, () => []); //同上，無則為其建立紀錄空間

    final position = positionMap[key]!; //指向該商品的空間
    final buyLots = buyLotMap[key]!;

    if (trade.type == TradeType.buy) { //買進：新增一批lot
      final costPerShare = (trade.amount + trade.fee) / trade.quantity;
      buyLots.add(BuyLot( //加入map
        quantity: trade.quantity,
        costPerShare: costPerShare,
      ));
      position.quantity += trade.quantity;
      position.totalCost += trade.amount + trade.fee;

      tradePnLMap[trade.id] = 0; //買入損益為0
      position.firstBuyDate ??= trade.date; //記錄第一次買入日期，??=:null才給值
    } else { //賣出：FIFO吃掉買進
      int sellQty = trade.quantity; //賣出數量
      final sellPrice = trade.price; //賣出金額
      final feePerShare = trade.fee / trade.quantity; //單位手續費
      final taxPerShare = trade.tax / trade.quantity; //單位交易稅
      double thisTradeRealizedPnL = 0;

      while (sellQty > 0 && buyLots.isNotEmpty) { //當要賣且尚有庫存時
        final lot = buyLots.first; //最先買進的那筆
        final usedQty = sellQty <= lot.quantity ? sellQty : lot.quantity; //判斷lot那筆購不購賣
        final cost = usedQty * lot.costPerShare; //計算lot那筆的成本
        final revenue = usedQty * (sellPrice - feePerShare - taxPerShare);
        final pnl = revenue - cost;

        position.realizedPnL += pnl;
        thisTradeRealizedPnL += pnl;

        lot.quantity -= usedQty; //減去lot那筆賣掉的量
        sellQty -= usedQty; //要賣出的總數減去已經賣掉的，還要賣則進下一輪迴圈
        position.quantity -= usedQty; //總庫存減少
        position.totalCost -= cost;

        if (lot.quantity == 0) { //lot如果賣完則刪除
          buyLots.removeAt(0);
        }
      }
      tradePnLMap[trade.id] = thisTradeRealizedPnL; //記錄這筆賣出的損益
    }
  }

    // 🆕 在 return 之前，套用股票股利
  final sortedDivs = dividends
    .where((d) => d.type == DividendType.stock)
    .toList()
    ..sort((a,b) => a.date.compareTo(b.date));

  for (final div in sortedDivs) {
    final pos = positionMap[div.symbol];
    if (pos == null || pos.quantity == 0) continue;
    // 增加股數，成本不變 → 均價稀釋
    pos.quantity += div.shareAmount;
    // totalCost 不變，avgCost 自動被 getter 重算
  }


  return PositionResult(
    positions: positionMap.values.toList(),
    tradePnLMap: tradePnLMap,
  );
}

//個股績效計算服務
List<StockPerformance> buildPerformances(List<Trade> trades) {
  final Map<String, _PerfAccum> map = {}; //存個股的累計資料
  final Map<String, List<BuyLot>> buyLotMap = {};

  final sorted = [...trades]
    ..sort((a, b) => a.date.compareTo(b.date));

  for (final trade in sorted) {
    final key = trade.symbol;
    map.putIfAbsent(key, () => _PerfAccum( //檢查有無該商品，無則建立該商品空間
      symbol: trade.symbol, name: trade.name));
    buyLotMap.putIfAbsent(key, () => []); //同上

    final acc = map[key]!;
    final buyLots = buyLotMap[key]!;

    if (trade.type == TradeType.buy) {
      acc.buyCount++; //買進次數+1
      acc.totalBuyAmount += trade.amount + trade.fee; //個股總買進金額
      acc.heldQty += trade.quantity; //持有股數
      buyLots.add(BuyLot( //記錄一筆交易
        quantity: trade.quantity,
        costPerShare: (trade.amount + trade.fee) / trade.quantity,
      ));
    } else {
      acc.sellCount++; //賣出次數+1
      acc.totalSellAmount += trade.sellIncome; //個股總賣出金額
      int sellQty = trade.quantity; //賣出股數
      double tradePnL = 0; //交易損益
      final feePerShare = trade.fee / trade.quantity;
      final taxPerShare = trade.tax / trade.quantity;

      while (sellQty > 0 && buyLots.isNotEmpty) { //當要賣且尚有庫存時
        final lot = buyLots.first; //最先買進的那筆
        final used = sellQty <= lot.quantity ? sellQty : lot.quantity;
        final cost = used * lot.costPerShare;
        final rev = used * (trade.price - feePerShare - taxPerShare);
        tradePnL += rev - cost;
        lot.quantity -= used;
        sellQty -= used;
        acc.heldQty -= used;
        if (lot.quantity == 0) buyLots.removeAt(0);
      }

      acc.totalRealizedPnL += tradePnL; //紀錄損益
      if (tradePnL > 0) acc.winCount++; //獲利次數記錄
    }
  }

  return map.values.map((acc) => StockPerformance(
    symbol: acc.symbol,
    name: acc.name,
    totalRealizedPnL: acc.totalRealizedPnL,
    totalBuyCount: acc.buyCount,
    totalSellCount: acc.sellCount,
    winCount: acc.winCount,
    totalBuyAmount: acc.totalBuyAmount,
    totalSellAmount: acc.totalSellAmount,
    isOpen: acc.heldQty > 0,
  )).toList()
  ..sort((a, b) =>
    b.totalRealizedPnL.compareTo(a.totalRealizedPnL));
}

//內部用的累加器
class _PerfAccum {
  final String symbol;
  final String name;
  double totalRealizedPnL = 0;
  int buyCount = 0;
  int sellCount = 0;
  int winCount = 0;
  double totalBuyAmount = 0;
  double totalSellAmount = 0;
  int heldQty = 0;
  _PerfAccum({required this.symbol, required this.name});
}