// 庫存計算服務
import '../models/trade.dart';
import '../models/position.dart';

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

PositionResult buildPositions(List<Trade> trades) { //FIFO主函式
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
    } else { //賣出：FIFO吃掉買進
      int sellQty = trade.quantity; //賣出數量
      final sellPrice = trade.price; //賣出金額
      final feePerShare = trade.fee / trade.quantity; //單位手續費
      final taxPerShare = trade.tax / trade.quantity; //單位交易稅
      double thisTradeRealizedPnL = 0;

      while (sellQty > 0 && buyLots.isNotEmpty) { //當要賣且尚有空存時
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
  return PositionResult(
    positions: positionMap.values.toList(),
    tradePnLMap: tradePnLMap,
  );
}