//交易資料庫存取邏輯
import 'package:flutter/foundation.dart';
import '../models/trade.dart';
import 'package:hive/hive.dart';

class TradeRepository extends ChangeNotifier {
  static const String boxName = 'tradesBox';

  late Box<Trade> _box; //建立資料儲存空間
  List<Trade> _trades = []; //清單

  TradeRepository() {
    _init();
  }

  Future<void> _init() async { //初始化
    _box = await Hive.openBox<Trade>(boxName);
    _trades = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  List<Trade> getAllTrades() { //取得交易資料
    return List.unmodifiable(_trades);
  }

  Future<void> addTrade(Trade trade) async { //新增
    await _box.put(trade.id, trade);
    _reloadTrades();
    notifyListeners();
  }

  Future<void> removeTrade(Trade trade) async { //刪除
    await _box.delete(trade.id);
    _reloadTrades();
    notifyListeners();
  }

  Future<void> updateTrade(Trade oldTrade, Trade newTrade) async { //更新
    await _box.put(oldTrade.id, newTrade);
    _reloadTrades();  
    notifyListeners();
  }

  Future<void> clear() async { //清空
    await _box.clear();
    _trades.clear();
    notifyListeners();
  }

  void _reloadTrades() { //更新並排序
    _trades = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}