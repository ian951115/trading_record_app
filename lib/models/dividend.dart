//股利模型
class Dividend {
  final DateTime date;
  final String symbol;
  final double amount;

  const Dividend({
    required this.date,
    required this.symbol,
    required this.amount,
  });
}