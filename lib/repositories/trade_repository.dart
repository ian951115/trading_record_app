//交易資料庫存取邏輯
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/trade.dart';

class TradeRepository extends ChangeNotifier {
  static const String boxName = 'tradesBox';

  late Box<Trade> _box; //建立資料儲存空間
  List<Trade> _trades = []; //清單
  bool _isReady = false; //確定初始化好了沒

  bool get isReady => _isReady;

  TradeRepository() {
    _init(); //這是async，但constructor不會等它完成跑完就結束了，所以有時候Provider在
  } //_init()還沒完成之前就有人來讀資料，_box還沒被賦值，就報錯了，所以要確定初始化好了沒

  Future<void> _init() async { //初始化
    _box = await Hive.openBox<Trade>(boxName);
    _trades = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _isReady = true;
    notifyListeners();
  }

  List<Trade> getAllTrades() { //取得交易資料
    if (!_isReady) return []; //還沒準備好就回傳空的
    return List.unmodifiable(_trades);
  }

  Future<void> addTrade(Trade trade) async { //新增
    if (!_isReady) return;
    await _box.put(trade.id, trade);
    _reloadTrades();
    notifyListeners();
  }

  Future<void> removeTrade(Trade trade) async { //刪除
    if (!_isReady) return;

    final key = _box.keys.firstWhere(
      (k) => _box.get(k)?.id == trade.id,
      orElse: () => trade.id,
    );

    await _box.delete(key);
    _reloadTrades();
    notifyListeners();
  }

  Future<void> updateTrade(Trade oldTrade, Trade newTrade) async { //更新
    if (!_isReady) return;

    // 找出 box 裡實際對應這個 trade 物件的 key
    final key = _box.keys.firstWhere(
      (k) => _box.get(k)?.id == oldTrade.id,
      orElse: () => oldTrade.id, //找不到就用 oldTrade.id（新資料）
    );

    await _box.put(key, newTrade);
    _reloadTrades();  
    notifyListeners();
  }

  Future<void> clear() async { //清空
    if (!_isReady) return;
    await _box.clear();
    _trades.clear();
    notifyListeners();
  }

  void _reloadTrades() { //更新並排序
    _trades = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}