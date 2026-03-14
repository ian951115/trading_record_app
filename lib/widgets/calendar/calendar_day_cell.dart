//日期格子資訊顯示元件
import 'package:flutter/material.dart';
import '../../models/daily_pnl.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final DailyPnl? daily; //?表daily可能是null，下面daily!表保證變數不是null
  final bool isSelected;
  final bool isToday;
  final String Function(double) formatPnL;
  final Color Function(double) heatmapColor;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.daily,
    required this.formatPnL,
    required this.heatmapColor,
    this.isSelected = false,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: daily != null //格子底色
            ? heatmapColor(daily!.pnl)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: isSelected //用邊框表示狀態
            ? Border.all(color: Colors.deepPurple, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Align( //右上方日期
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                  color: (isSelected || isToday) ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
          ),
          const Spacer(),
          if (daily != null && daily!.pnl != 0) //下方資訊
            Text(
              formatPnL(daily!.pnl),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: daily!.pnl >=0 ? Colors.red : Colors.green,
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }
}