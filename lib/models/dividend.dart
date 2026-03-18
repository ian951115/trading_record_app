//股利模型
import 'package:hive/hive.dart';

part 'dividend.g.dart';

@HiveType(typeId: 5)
class Dividend {
  @HiveField(0)
  final DateTime date;
  @HiveField(1)
  final String symbol;
  @HiveField(2)
  final double amount;

  const Dividend({
    required this.date,
    required this.symbol,
    required this.amount,
  });
}