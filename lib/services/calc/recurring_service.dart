//定期定額邏輯服務
import '../../models/recurring_plan.dart';
import '../../models/trade.dart';

// ── 單筆待確認項目 ──────────────────────────────
class PendingEntry {
  final RecurringPlan plan;
  final DateTime scheduledDate; //應扣款日

  const PendingEntry({
    required this.plan,
    required this.scheduledDate,
  });
}

// ── 主服務 ──────────────────────────────────────
class RecurringService {

  //取得計畫「從開始日到今天」所有應扣款日清單
  static List<DateTime> getScheduledDates(RecurringPlan plan) {
    final result = <DateTime>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    //從計畫開始的那個月逐月掃描
    var cursor = DateTime(plan.startDate.year, plan.startDate.month, 1);

    while (!cursor.isAfter(today)) {
      for (final day in plan.dayOfMonth) {
        try{
          DateTime d = DateTime(cursor.year, cursor.month, day);
          //周末順延
          if (d.weekday == DateTime.saturday) d = d.add(const Duration(days: 2));
          if (d.weekday == DateTime.sunday) d = d.add(const Duration(days: 1));
          if (!d.isBefore(plan.startDate) && !d.isAfter(today)) {
            result.add(d);
          }
        } catch (_) {
          //無效日期（e.g. 2月30日）跳過
        }
      }
      //移到下個月
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return result..sort();
  }

  //取得「還沒有對應買入紀錄」的扣款日（待確認清單）
  static List<PendingEntry> getPendingEntries({
    required RecurringPlan plan,
    required List<Trade> allTrades,
  }) {
    final scheduled = getScheduledDates(plan);

    //取出該股票所有買入日期（只看日期，不看時間）
    final buyDates = allTrades
        .where((t) =>
            t.symbol == plan.symbol &&
            t.type == TradeType.buy &&
            t.note == '定期定額')
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();

    return scheduled
        .where((d) => !buyDates.contains(d)) //找出預計要買但還沒買的天
        .map((d) {
          return PendingEntry(
            plan: plan,
            scheduledDate: d,
          );
        })
        .toList();
  }

  //取得所有啟用計畫的待確認清單（合併）
  static List<PendingEntry> getAllPendingEntries({
    required List<RecurringPlan> activePlans,
    required List<Trade> allTrades,
  }) {
    final result = <PendingEntry>[];
    for (final plan in activePlans) {
      result.addAll(
        getPendingEntries(
          plan: plan,
          allTrades: allTrades,
        )
      );
    }
    //依日期排序（最舊的在前）
    result.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return result;
  }

  //計算下次扣款日（今天或今天以後最近的一個）
  static DateTime? nextScheduledDate(RecurringPlan plan) {
    if (!plan.isActive) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [...plan.dayOfMonth]..sort();

    //本月還有沒到的扣款日
    for (final day in days) {
      try {
        final candidate = DateTime(today.year, today.month, day);
        if (!candidate.isBefore(today)) return candidate;
      } catch (_) {}
    }

    //下個月第一個扣款日
    final nextMonth = DateTime(today.year, today.month + 1, 1);
    for (final day in days) {
      try {
        return DateTime(nextMonth.year, nextMonth.month, day);
      } catch (_) {}
    }
    return null;
  }

  //根據金額和價格估算可買股數（無條件捨去）
  static int estimateShares({
    required double amount,
    required double price,
  }) {
    if (price <= 0) return 0;
    return (amount / price).floor();
  }
}
