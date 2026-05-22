//日期格子資訊顯示元件
import 'package:flutter/material.dart';
import '../../models/daily_pnl.dart';
import '../../core/app_colors.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final DailyPnl? daily; //?表daily可能是null，下面daily!表保證變數不是null
  final bool isSelected;
  final bool isToday;
  final int tradeCount;
  final String Function(double) formatPnL;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.daily,
    required this.formatPnL,
    required this.tradeCount,
    this.isSelected = false,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPnL = daily != null && daily!.pnl != 0;
    final pnl = daily?.pnl ?? 0;

    final bgColor = !hasPnL //底色
        ? Colors.transparent
        : pnl > 0
            ? AppColors.profitBgStrong
            : AppColors.lossBgStrong;

    final overlayColor = isSelected //選中狀態：疊加半透明深色保留底色
        ? AppColors.primary.withValues(alpha: 0.15)
        : Colors.transparent;

    final border = isToday //今天邊框
        ? Border.all(color: AppColors.primary, width: 1.5)
        : isSelected
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null;

    final dayNumColor = isToday //日期數字顏色
        ? AppColors.primary
        : isSelected
            ? AppColors.primary
            : AppColors.textSecond;

    final pnlColor = AppColors.pnl(pnl); //損益文字顏色

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
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
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
                    Text(
                      '$tradeCount 筆',
                      style: const TextStyle(fontSize: 7, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                  ],
                ),
            ],
          ),
        ]
      )
    );
  }
}