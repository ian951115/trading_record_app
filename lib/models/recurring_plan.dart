//定期定額計畫model
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'pause_period.dart';

part 'recurring_plan.g.dart';

// ── 頻率（目前只有 monthly，之後可擴充）──────────
@HiveType(typeId: 8)
enum RecurringFrequency {
  @HiveField(0)
  monthly, // 每月指定日期
}

// ── 定期定額計畫 ──────────────────────────────────
@HiveType(typeId: 9)
class RecurringPlan {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String symbol; //股票代碼，e.g."0050"
  @HiveField(2)
  final String name; //股票名稱，e.g."元大台灣50"
  @HiveField(3)
  final RecurringFrequency frequency;
  @HiveField(4)
  final List<int> dayOfMonth; //每月幾號扣款，可多個，e.g. [5, 20]
  @HiveField(5)
  final double amountPerTime; //每次扣款金額（元）
  @HiveField(6)
  bool isActive; //是否啟用，可暫停
  @HiveField(7)
  final DateTime startDate; //計畫開始日
  @HiveField(8)
  final String? note; //備註（選填）
  @HiveField(9)
  final List<PausePeriod> pausedPeriods; //暫停區間紀錄

  RecurringPlan({
    String? id,
    required this.symbol,
    required this.name,
    required this.frequency,
    required this.dayOfMonth,
    required this.amountPerTime,
    this.isActive = true,
    required this.startDate,
    this.note,
    List<PausePeriod>? pausedPeriods,
  }) : id = id ?? const Uuid().v4(),
      pausedPeriods = pausedPeriods ?? [];

  // 每月總扣款金額（次數 × 每次金額）
  double get monthlyAmount => amountPerTime * dayOfMonth.length;

  // 建立修改版本（Hive 物件不可變，需整個換掉）
  RecurringPlan copyWith({
    String? symbol,
    String? name,
    RecurringFrequency? frequency,
    List<int>? dayOfMonth,
    double? amountPerTime,
    bool? isActive,
    DateTime? startDate,
    String? note,
    List<PausePeriod>? pausedPeriods,
  }) {
    return RecurringPlan(
      id: id, //id不變
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      amountPerTime: amountPerTime ?? this.amountPerTime,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      note: note ?? this.note,
      pausedPeriods: pausedPeriods ?? this.pausedPeriods,
    );
  }
}
