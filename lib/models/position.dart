//庫存模型
import 'trade.dart';

class Position { //all
  final String symbol;
  final String name;
  int quantity = 0; //現在還剩幾股
  double totalCost = 0; //尚未賣出的持倉成本
  double realizedPnL =0; //已實現損益（賣出） PnL=Profit and Loss

  Position({
    required this.symbol,
    required this.name,
  });

  double get avgCost => quantity == 0 ? 0 : totalCost / quantity;

  double get mockPrice => avgCost * 1.05; //暫時假設漲5%，只是讓畫面能跑
  double get marketValue => mockPrice * quantity; //市值
  double get unrealizedPnL => marketValue - totalCost; //未實現損益
  double get unrealizedReturn => //未實現報酬率
       totalCost == 0 ? 0 : (unrealizedPnL / totalCost) * 100;
}