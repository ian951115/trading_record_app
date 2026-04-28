//自訂目標資庫存取邏輯
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/custom_goal.dart';

class CustomGoalRepository extends ChangeNotifier {
  static const String boxName = 'custom_goals';
  late Box<CustomGoal> _box;
  List<CustomGoal> _goals = [];
  bool _isReady = false;
  bool get isReady => _isReady;
 
  CustomGoalRepository() {
    _init();
  }
 
  Future<void> _init() async {
    _box = await Hive.openBox<CustomGoal>(boxName);
    _reload();
    _isReady = true;
    notifyListeners();
  }
 
  // 全部目標，依截止日升序（進行中的先出現）
  List<CustomGoal> getAll() => List.unmodifiable(_goals);
 
  Future<void> add(CustomGoal g) async {
    await _box.put(g.id, g);
    _reload();
    notifyListeners();
  }

  Future<void> update(CustomGoal g) async {
    await _box.put(g.id, g);
    _reload();
    notifyListeners();
  }
  Future<void> delete(String id) async {
    await _box.delete(id);
    _reload();
    notifyListeners();
  }
 
  void _reload() {
    _goals = _box.values.toList()
      ..sort((a, b) => a.endDate.compareTo(b.endDate));
  }
}
