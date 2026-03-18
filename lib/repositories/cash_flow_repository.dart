//資金資料庫存取邏輯
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/cash_flow.dart';

class CashFlowRepository extends ChangeNotifier {
  static const String boxName = 'cash_flows';

  late Box<CashFlow> _box;
  List<CashFlow> _flows = [];
  bool _isReady = false;

  bool get isReady => _isReady;

  CashFlowRepository() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CashFlow>(boxName);
    _flows = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _isReady = true;
    notifyListeners();
  }

  List<CashFlow> getAllFlows() {
    if (!_isReady) return [];
    return List.unmodifiable(_flows);
  }

  Future<void> addFlow(CashFlow flow) async {
    if (!_isReady) return;
    await _box.put(flow.id, flow);
    _reloadFlows();
    notifyListeners();
  }

  Future<void> removeFlow(String id) async {
    if (!_isReady) return;
    await _box.delete(id);
    _reloadFlows();
    notifyListeners();
  }

  Future<void> updateFlow(CashFlow flow) async {
    if (!_isReady) return;
    await _box.put(flow.id, flow);
    _reloadFlows();
    notifyListeners();
  }

  Future<void> clear() async {
    if (!_isReady) return;
    await _box.clear();
    _flows.clear();
    notifyListeners();
  }

  double get totalNetCashFlow {
    if (!_isReady) return 0;
    return _box.values.fold(
      0.0,
      (sum, flow) => sum + flow.netAmount,
    );
  }

  double get totalDeposit {
    if (!_isReady) return 0;
    return _box.values
        .where((f) => f.type == CashFlowType.deposit)
        .fold(0.0, (sum, f) => sum + f.amount);
  }

  double get totalWithdraw {
    if (!_isReady) return 0;
    return _box.values
        .where((f) => f.type == CashFlowType.withdraw)
        .fold(0.0, (sum, f) => sum + f.amount);
  }

  void _reloadFlows() {
    _flows = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}