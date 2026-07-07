//多格摘要數據列(白卡)，用於頁面頂部統計資訊
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class StatCell {
  final String label;
  final String value;
  final Color? valueColor;

  const StatCell({
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class StatsStrip extends StatelessWidget {
  final List<StatCell> cells;

  const StatsStrip({
    super.key,
    required this.cells,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight( //內部高度?
        child: Row(
          children: [
            for (int i = 0; i < cells.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  color: const Color(0xFFE4E7ED),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  child: Column(
                    children: [
                      Text(
                        cells[i].label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cells[i].value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cells[i].valueColor ?? const Color(0xFF1A1F2E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}