//月份格子資訊顯示元件
import 'package:flutter/material.dart';
import '../charts/mini_sparkline.dart';
import '../../services/calc/pnl_service.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';

class CalendarMonthCell extends StatelessWidget {
  final int month;
  final YearMonthData? data;
  final String Function(double) formatPnL;
  final VoidCallback onTap;

  const CalendarMonthCell({
    super.key,
    required this.month,
    required this.data,
    required this.formatPnL,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pnl = data?.totalPnL ?? 0;
    final hasData = data != null && data!.tradeCount > 0;

    Color bgColor, borderColor;
    if (!hasData) {
      bgColor = Colors.white;
      borderColor = AppColors.border;
    } else if (pnl > 0) {
      bgColor = AppColors.profitBgStrong;
      borderColor = AppColors.profitBorder;
    } else if (pnl < 0) {
      bgColor = AppColors.lossBgStrong;
      borderColor = AppColors.lossBorder;
    } else {
      bgColor = const Color(0xFFF7F8FA);
      borderColor = AppColors.border;
    }

    final pnlColor = AppColors.pnl(pnl);
    final pnlText = !hasData ? '—' : AppFmt.pnl(pnl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text( //月份標題
              '$month 月',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecond,
              ),
            ),
            if (hasData) //迷你走勢線（有資料才顯示）
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  height: 20, width: double.infinity,
                  child: Opacity(
                    opacity: 0.6,
                    child: MiniSparkline(data: data!.equitySequence),
                  ),
                ),
              )
            else
              const SizedBox(height: 28),

            const Spacer(),
            Text( //損益金額
              pnlText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: pnlColor,
              ),
            ),

            if (hasData) //交易筆數 + 勝率
              Text(
                '${data!.tradeCount} 筆・${(data!.winRate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}