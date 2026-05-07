//自定義目標model
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../core/enum_ext.dart';
import 'goal_type.dart';

part 'custom_goal.g.dart';
 
@HiveType(typeId: 11)
class CustomGoal {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String goalTypeStr;
  
  @HiveField(3)
  final String? stockSymbol;
  
  @HiveField(4)
  final String? stockName;
  
  @HiveField(5)
  final double targetAmount;
  
  @HiveField(6)
  final DateTime startDate;
  
  @HiveField(7)
  final DateTime endDate;
  
  @HiveField(8)
  final String? note;
 
  CustomGoal({
    String? id,
    required this.title,
    required String goalTypeStr,
    this.stockSymbol,
    this.stockName,
    required this.targetAmount,
    required this.startDate,
    required this.endDate,
    this.note,
  }) : id = id ?? const Uuid().v4(),
      goalTypeStr = goalTypeStr;
 
  GoalType get goalType =>
    GoalType.values.byNameOrNull(goalTypeStr) ?? GoalType.totalPnL;
 
  int get daysLeft =>
    endDate.difference(DateTime.now()).inDays.clamp(0, 9999);
 
  CustomGoalStatus getStatus(double realizedPnL) {
    if (realizedPnL >= targetAmount) return CustomGoalStatus.achieved;
    if (DateTime.now().isAfter(endDate))  return CustomGoalStatus.ended;
    return CustomGoalStatus.ongoing;
  }
 
  CustomGoal copyWith({
    String? id,
    String? title,
    String? goalTypeStr,
    String? stockSymbol,
    String? stockName,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
  }) => CustomGoal(
    id: id,
    title: title ?? this.title,
    goalTypeStr: goalTypeStr ?? this.goalTypeStr,
    stockSymbol: stockSymbol ?? this.stockSymbol,
    stockName: stockName ?? this.stockName,
    targetAmount: targetAmount ?? this.targetAmount,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    note: note ?? this.note,
  );
}