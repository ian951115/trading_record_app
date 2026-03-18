//複合資料回傳模型，例如新增交易頁面的回傳結果
import 'trade.dart';
import 'cash_flow.dart';

class AddTradeResult {
  final Trade trade;
  final CashFlow? autoDeposit; // 若使用者沒開啟同時入金，則為 null

  const AddTradeResult({
    required this.trade,
    this.autoDeposit,
  });
}