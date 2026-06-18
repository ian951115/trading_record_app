//定期定額暫停時期
import 'package:hive/hive.dart';

part 'pause_period.g.dart';

@HiveType(typeId: 12)
class PausePeriod {
  @HiveField(0)
  final DateTime pausedAt; // 暫停開始日

  @HiveField(1)
  final DateTime? resumedAt; // 恢復日（null = 還在暫停中）

  const PausePeriod({
    required this.pausedAt,
    this.resumedAt,
  });

  // 判斷某日期是否落在此暫停區間內
  bool contains(DateTime date) {
    if (date.isBefore(pausedAt)) return false;
    if (resumedAt == null) return true; // 還在暫停中，之後所有日期都算
    return date.isBefore(resumedAt!);
  }
}