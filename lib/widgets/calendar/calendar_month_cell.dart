//月份格子資訊顯示元件
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../charts/mini_sparkline.dart';
import '../../services/calendar_service.dart';

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
    final formatter = NumberFormat('#,###');
    final pnl = data?.totalPnL ?? 0;
    final hasData = data != null && data!.tradeCount > 0;

    Color bgColor;
    Color borderColor;
    if (!hasData) {
      bgColor = Colors.white;
      borderColor = const Color(0xFFE4E7ED);
    } else if (pnl > 0) {
      bgColor = const Color(0xFFFDF0EF);
      borderColor = const Color(0xFFF5C4C2);
    } else if (pnl < 0) {
      bgColor = const Color(0xFFEEF7F2);
      borderColor = const Color(0xFFB8DFC9);
    } else {
      bgColor = const Color(0xFFF7F8FA);
      borderColor = const Color(0xFFE4E7ED);
    }

    final pnlColor = pnl > 0
        ? const Color(0xFFE8504A)
        : pnl < 0
            ? const Color(0xFF3D9E6B)
            : const Color(0xFF9AA3B2);

    final pnlText = !hasData
        ? '—'
        : (pnl > 0 ? '+' : '') + formatter.format(pnl.toInt());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text( //月份標題
              '$month 月',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A6375),
              ),
            ),
            if (hasData) //迷你走勢線（有資料才顯示）
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  height: 20,
                  width: double.infinity,
                  child: Opacity(
                    opacity: 0.6,
                    child: MiniSparkline(
                      data: data!.equitySequence,
                    ),
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
                  color: Color(0xFF9AA3B2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}