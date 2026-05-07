//年度目標model
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../core/enum_ext.dart';
import 'goal_type.dart';

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

  @HiveField(4)
  final String goalTypeStr; //存GoalType.name，預設"totalPnL"

  @HiveField(5)
  final String? stockSymbol;

  @HiveField(6)
  final String? stockName;

  // computed getter / setter
  GoalType get goalType =>
    GoalType.values.byNameOrNull(goalTypeStr) ?? GoalType.totalPnL;


  AnnualGoal({
    String? id,
    required this.year,
    required this.targetPnL,
    this.note,
    String? goalTypeStr,
    this.stockSymbol,
    this.stockName,
  }) : id = id ?? const Uuid().v4(),
      goalTypeStr = goalTypeStr ?? GoalType.totalPnL.name;

  AnnualGoal copyWith({
    int? year,
    double? targetPnL,
    String? note,
    String? goalTypeStr,
    String? stockSymbol,
    String? stockName,
  }) => AnnualGoal(
    id: id,
    year: year ?? this.year,
    targetPnL: targetPnL ?? this.targetPnL,
    note: note ?? this.note,
    goalTypeStr: goalTypeStr ?? this.goalTypeStr,
    stockSymbol: stockSymbol ?? this.stockSymbol,
    stockName: stockName ?? this.stockName,
  );
}