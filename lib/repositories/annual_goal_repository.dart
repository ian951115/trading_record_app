//年度目標資庫存取邏輯
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/annual_goal.dart';
import '../models/goal_type.dart';

class AnnualGoalRepository extends ChangeNotifier {
  static const String boxName = 'annual_goals';

  late Box<AnnualGoal> _box;
  List<AnnualGoal> _goals = [];
  bool _isReady = false;

  bool get isReady => _isReady;

  AnnualGoalRepository() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<AnnualGoal>(boxName);
    _reload();
    _isReady = true;
    notifyListeners();
  }

  // ── 讀取 ───────────────────────────────────────

  //全部目標（依年份降序：最新的在前）
  List<AnnualGoal> getAll() {
    if (!_isReady) return [];
    return List.unmodifiable(_goals);
  }

  //取得指定年份的目標（可能為 null）
  AnnualGoal? getByYear(int year) {
    if (!_isReady) return null;
    try {
      return _goals.firstWhere((g) => g.year == year);
    } catch (_) {
      return null;
    }
  }

  //是否已有該年份的目標
  bool hasGoalForYear(int year) => getByYear(year) != null;

  // ── 寫入 ───────────────────────────────────────

  Future<void> add(AnnualGoal goal) async {
    if (!_isReady) return;
    await _box.put(goal.id, goal);
    _reload();
    notifyListeners();
  }

  Future<void> update(AnnualGoal goal) async {
    if (!_isReady) return;
    await _box.put(goal.id, goal);
    _reload();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    if (!_isReady) return;
    await _box.delete(id);
    _reload();
    notifyListeners();
  }

  // ── 內部 ───────────────────────────────────────

  void _reload() {
    _goals = _box.values.toList()
      ..sort((a, b) => b.year.compareTo(a.year)); //最新年份在前
  }

  // 回傳 Map<year, List<AnnualGoal>>，依年份降序排列
  // 同年內：totalPnL 固定第一，其餘保持插入順序
  Map<int, List<AnnualGoal>> getGroupedByYear() {
    final map = <int, List<AnnualGoal>>{};
    for (final g in _goals) { // _goals 已依 year desc 排序
      map.putIfAbsent(g.year, () => []).add(g);
    }
    map.forEach((_, list) {
      list.sort((a, b) {
        if (a.goalType == GoalType.totalPnL) return -1; //a在b前面
        if (b.goalType == GoalType.totalPnL) return  1; //反之
        return 0;
      });
    });
    return map;
  }
 
  // 同年同標的只能有一個，新增前用此方法檢查
  bool hasGoalForYearAndType(int year, GoalType type, {String? symbol}) {
    return _goals.any((g) =>
      g.year == year &&
      g.goalType == type &&
      (type == GoalType.totalPnL || g.stockSymbol == symbol),
    );
  }

  Future<void> clear() async {
    await _box.clear();
    _goals.clear();
    notifyListeners();
  }
}
