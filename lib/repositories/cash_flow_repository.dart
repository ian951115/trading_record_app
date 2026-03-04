//資金資料中心
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/cash_flow.dart';

class CashFlowRepository extends ChangeNotifier {
  static const String boxName = 'cash_flows';

  late Box<CashFlow> _box;

  CashFlowRepository() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CashFlow>(boxName);
    notifyListeners();
  }

  List<CashFlow> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> add(CashFlow flow) async {
    await _box.put(flow.id, flow);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  Future<void> update(CashFlow flow) async {
    await _box.put(flow.id, flow);
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
}