//定期定額資料存取邏輯
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_plan.dart';
import '../models/pause_period.dart';

class RecurringRepository extends ChangeNotifier {
  static const String boxName = 'recurring_plans';

  late Box<RecurringPlan> _box;
  List<RecurringPlan> _plans = [];
  bool _isReady = false;

  bool get isReady => _isReady;

  RecurringRepository() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<RecurringPlan>(boxName);
    _reload();
    _isReady = true;
    notifyListeners();
  }

  // ── 讀取 ───────────────────────────────────────

  // 全部計畫（依開始日排序）
  List<RecurringPlan> getAll() {
    if (!_isReady) return [];
    return List.unmodifiable(_plans);
  }

  // 只取啟用中的計畫
  List<RecurringPlan> getActive() {
    if (!_isReady) return [];
    return _plans.where((p) => p.isActive).toList();
  }

  // ── 寫入 ───────────────────────────────────────

  Future<void> add(RecurringPlan plan) async {
    if (!_isReady) return;
    await _box.put(plan.id, plan);
    _reload();
    notifyListeners();
  }

  Future<void> update(RecurringPlan plan) async {
    if (!_isReady) return;
    await _box.put(plan.id, plan);
    _reload();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    if (!_isReady) return;
    await _box.delete(id);
    _reload();
    notifyListeners();
  }

  // 切換啟用/暫停
  Future<void> toggleActive(RecurringPlan plan) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final periods = List<PausePeriod>.from(plan.pausedPeriods);

    if (plan.isActive) {
      //啟用 → 暫停：新增一筆開啟中的暫停區間
      periods.add(PausePeriod(pausedAt: today));
    } else {
      //暫停 → 恢復：找到最後一筆未結束的區間，補上resumedAt
      final lastIndex = periods.lastIndexWhere((p) => p.resumedAt == null);
      if (lastIndex != -1) {
        periods[lastIndex] = PausePeriod(
          pausedAt: periods[lastIndex].pausedAt,
          resumedAt: today,
        );
      }
    }

    final updated = plan.copyWith(
      isActive: !plan.isActive,
      pausedPeriods: periods,
    );
    await update(updated);
  }

  // ── 內部 ───────────────────────────────────────

  void _reload() {
    _plans = _box.values.toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Future<void> clear() async {
    if (!_isReady) return;
    await _box.clear();
    _plans.clear();
    notifyListeners();
  }
}
