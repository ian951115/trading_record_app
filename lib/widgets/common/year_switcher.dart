//年份切換元件
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class YearSwitcher extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;

  /// 顯示文字，預設「{year} 年」；月視圖可傳 '{year} 年 {month} 月'
  final String? label;

  const YearSwitcher({
    super.key,
    required this.year,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavBtn(onTap: () => onChanged(year - 1), icon: Icons.chevron_left),
        const SizedBox(width: 16),
        Text(
          label ?? '$year 年',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1F2E),
          ),
        ),
        const SizedBox(width: 16),
        _NavBtn(onTap: () => onChanged(year + 1), icon: Icons.chevron_right),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const _NavBtn({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC5D4EC)),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}