//資金資料庫存取邏輯
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/cash_flow.dart';

class CashFlowRepository extends ChangeNotifier {
  static const String boxName = 'cash_flows';

  late Box<CashFlow> _box;
  List<CashFlow> _flows = [];

  CashFlowRepository() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CashFlow>(boxName);
    _flows = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  List<CashFlow> getAllFlows() {
    return List.unmodifiable(_flows);
  }

  Future<void> addFlow(CashFlow flow) async {
    await _box.put(flow.id, flow);
    _reloadFlows();
    notifyListeners();
  }

  Future<void> removeFlow(String id) async {
    await _box.delete(id);
    _reloadFlows();
    notifyListeners();
  }

  Future<void> updateFlow(CashFlow flow) async {
    await _box.put(flow.id, flow);
    _reloadFlows();
    notifyListeners();
  }

  Future<void> clear() async {
    await _box.clear();
    _flows.clear();
    notifyListeners();
  }

  double get totalNetCashFlow {
    return _box.values.fold(
      0.0,
      (sum, flow) => sum + flow.netAmount,
    );
  }

  double get totalDeposit {
    return _box.values
        .where((f) => f.type == CashFlowType.deposit)
        .fold(0.0, (sum, f) => sum + f.amount);
  }

  double get totalWithdraw {
    return _box.values
        .where((f) => f.type == CashFlowType.withdraw)
        .fold(0.0, (sum, f) => sum + f.amount);
  }

  void _reloadFlows() {
    _flows = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}