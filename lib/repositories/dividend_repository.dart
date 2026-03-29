//股利計算服務
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/dividend.dart';

class DividendRepository extends ChangeNotifier {
  static const String boxName = 'dividends';

  late Box<Dividend> _box;
  List<Dividend> _dividends = [];
  bool _isReady = false;

  bool get isReady => _isReady;

  DividendRepository() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<Dividend>(boxName);
    _dividends = _box.values.toList()
      ..sort((a,b) => b.date.compareTo(a.date));
    _isReady = true;
    notifyListeners();
  }

  List<Dividend> getAllDividends() {
    if (!_isReady) return [];
    return List.unmodifiable(_dividends);
  }

  Future<void> addDividend(Dividend div) async {
    if (!_isReady) return;
    await _box.put(div.id, div);
    _reload();
    notifyListeners();
  }

  Future<void> removeDividend(String id) async {
    if (!_isReady) return;
    await _box.delete(id);
    _reload();
    notifyListeners();
  }

  Future<void> updateDividend(Dividend div) async {
    if (!_isReady) return;
    await _box.put(div.id, div);
    _reload();
    notifyListeners();
  }

  void _reload() {
    _dividends = _box.values.toList()
      ..sort((a,b) => b.date.compareTo(a.date));
  }

  double get totalCashDividend => _dividends //總現金股利
    .where((d) => d.type == DividendType.cash)
    .fold(0.0, (s, d) => s + d.cashAmount);

  double get totalNetCashDividend => _dividends //總淨現金股利
    .where((d) => d.type == DividendType.cash)
    .fold(0.0, (s, d) => s + d.netCashAmount);

  double get totalFee => _dividends //總手續費
    .fold(0.0, (s, d) => s + d.fee);

  double get totalHealthInsurance => _dividends //總二代健保
    .fold(0.0, (s, d) => s + d.healthInsurance);

  int get totalShareDividend => _dividends //總股票股利
    .where((d) => d.type == DividendType.stock)
    .fold(0, (s, d) => s + d.shareAmount);
}
