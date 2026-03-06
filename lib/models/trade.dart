//一筆交易的 模型/範本
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

part 'trade.g.dart';

@HiveType(typeId: 1)
enum TradeType {
  @HiveField(0)
  buy,
  @HiveField(1)
  sell,
}

@HiveType(typeId: 0)
class Trade {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String symbol; //股票/商品代碼
  @HiveField(3)
  final String name; //名稱
  @HiveField(4)
  final TradeType type;
  @HiveField(5)
  final double price;
  @HiveField(6)
  final int quantity;
  @HiveField(7)
  final double fee; //手續費
  @HiveField(8)
  final double tax; //證交稅
  @HiveField(9)
  final String? note; //備註
  @HiveField(10)
  final List<String> tags; //策略/標籤

  Trade({
    String? id,
    required this.date,
    required this.symbol,
    required this.name,
    required this.type,
    required this.price,
    required this.quantity,
    this.fee = 0,
    this.tax = 0,
    this.note,
    this.tags = const [],
  }) : id = id ?? const Uuid().v4();

  double get amount => price * quantity;
  double get buyCost => amount + fee;
  double get sellIncome => amount - fee - tax;
  double get netAmount {
    if(type == TradeType.buy) {
      return -buyCost;
    }else{
      return sellIncome;
    }
  }

  @override
  String toString() {
    return 'Trade($symbol, $type, net=$netAmount)';
  }
}