//資金管理的儲存模板
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'cash_flow.g.dart';

@HiveType(typeId: 2)
enum CashFlowType {
  @HiveField(0)
  deposit,
  @HiveField(1)
  withdraw,
}

@HiveType(typeId: 3)
class CashFlow {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final CashFlowType type;
  @HiveField(3)
  final double amount;
  @HiveField(4)
  final String? note;

  CashFlow({
    String? id,
    required this.date,
    required this.type,
    required this.amount,
    this.note,
  }) : id = id ?? const Uuid().v4();

  double get netAmount {
    if (type == CashFlowType.deposit) {
      return amount;
    } else {
      return -amount;
    }
  }
}