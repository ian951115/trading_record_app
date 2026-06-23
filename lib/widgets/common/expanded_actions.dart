//展開區底部操作列（編輯/刪除/外插按鈕）
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ExpandedActions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// 插入編輯左側的額外按鈕（可選），每個元素為完整 Expanded widget
  final List<Widget> extraActions;

  const ExpandedActions({
    super.key,
    this.onEdit,
    this.onDelete,
    this.extraActions = const [],
  });

  static Future<bool> confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('是否刪除這筆資料？\n此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.profit),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...extraActions.map((w) => w).followedBy([
          if (extraActions.isNotEmpty) const SizedBox(width: 6),
        ]),
        if (onEdit != null)
          Expanded(
            child: _ActionBtn(
              label: '編輯',
              icon: Icons.edit_outlined,
              color: AppColors.primaryLight,
              textColor: AppColors.primary,
              onTap: onEdit!,
            ),
          ),
        if (onEdit != null && onDelete != null) const SizedBox(width: 8),
        if (onDelete != null)
          Expanded(
            child: _ActionBtn(
              label: '刪除',
              icon: Icons.delete_outline,
              color: const Color(0xFFFDF0EF),
              textColor: AppColors.profit,
              onTap: onDelete!,
            ),
          ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}