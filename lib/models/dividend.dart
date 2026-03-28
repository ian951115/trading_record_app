//股利模型
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'dividend.g.dart';

@HiveType(typeId: 7)
enum DividendType {
  @HiveField(0)
  cash, //現金股利
  @HiveField(1)
  stock, //股票股利
}

@HiveType(typeId: 5)
class Dividend extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String symbol;
  @HiveField(3)
  final String name;
  @HiveField(4)
  final DividendType type;
  @HiveField(5)
  final double cashAmount; //現金金額（股票股利填0）
  @HiveField(6)
  final int shareAmount; //股數（現金股利填0）
  @HiveField(7)
  final double fee;
  @HiveField(8)
  final double healthInsurance; //二代健保
  @HiveField(9)
  final String? note;

  Dividend({
    String? id,
    required this.date,
    required this.symbol,
    required this.name,
    required this.type,
    this.cashAmount = 0,
    this.shareAmount = 0,
    this.fee = 0,
    this.healthInsurance = 0,
    this.note,
  }) : id = id ?? const Uuid().v4();

  // 實際入帳金額（現金股利用）
    double get netCashAmount =>
      cashAmount - fee - healthInsurance;

}