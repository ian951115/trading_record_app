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
    final hasPnL = daily != null && daily!.pnl != 0;
    final pnl = daily?.pnl ?? 0;

    final bgColor = hasPnL //熱力圖底色（有資料才套用）
        ? heatmapColor(pnl)
        : Colors.transparent;

    final overlayColor = isSelected //選中狀態：疊加半透明深色，保留熱力圖底色
        ? const Color(0xFF4A6FA5).withValues(alpha: 0.15)
        : Colors.transparent;

    final border = isToday //今天邊框
        ? Border.all(color: const Color(0xFF4A6FA5), width: 1.5)
        : isSelected
            ? Border.all(color: const Color(0xFF4A6FA5), width: 1.5)
            : null;

    final dayNumColor = isToday //日期數字顏色
        ? const Color(0xFF4A6FA5)
        : isSelected
            ? const Color(0xFF4A6FA5)
            : const Color(0xFF5A6375);

    final pnlColor = pnl >= 0 //損益文字顏色
        ? const Color(0xFFE8504A)
        : const Color(0xFF3D9E6B);


    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor, //格子底色
        borderRadius: BorderRadius.circular(6),
        border: border, //用邊框表示狀態
      ),
      child: Stack(
        children: [
          if (isSelected) //選中疊加層（保留底色）
            Container(
              decoration: BoxDecoration(
                color: overlayColor,
                borderRadius: BorderRadius.circular(6)
              ),
            ),

          Column(
            children: [
              Align( //右上方日期
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3, right: 4),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: (isSelected || isToday)
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: dayNumColor,
                    ),
                  ),
                ),
              ),

              const Spacer(),
              if (hasPnL) //下方資訊
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatPnL(pnl),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: pnlColor,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),

              const Spacer(),
            ],
          ),
        ]
      )
    );
  }
}

