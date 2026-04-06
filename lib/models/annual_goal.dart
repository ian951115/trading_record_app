//年度目標model
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'annual_goal.g.dart';

@HiveType(typeId: 10)
class AnnualGoal {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int year; //目標年份，e.g. 2026

  @HiveField(2)
  final double targetPnL; //目標損益金額（元），需 > 0

  @HiveField(3)
  final String? note; //備註（選填）

  AnnualGoal({
    String? id,
    required this.year,
    required this.targetPnL,
    this.note,
  }) : id = id ?? const Uuid().v4();

  AnnualGoal copyWith({
    int? year,
    double? targetPnL,
    String? note,
  }) {
    return AnnualGoal(
      id: id,
      year: year ?? this.year,
      targetPnL: targetPnL ?? this.targetPnL,
      note: note ?? this.note,
    );
  }
}
