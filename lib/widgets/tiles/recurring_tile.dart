//定期定額顯示元件
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recurring_plan.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../repositories/recurring_repository.dart';
import '../../services/calc/recurring_service.dart';
import '../common/expanded_actions.dart';
import '../common/info_item.dart';

class RecurringTile extends StatefulWidget {
  final RecurringPlan plan;
  final List trades; //用於計算下次扣款
  final VoidCallback onDelete, onEdit;
  const RecurringTile({
    super.key,
    required this.plan,
    required this.trades,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<RecurringTile> createState() => RecurringTileState();
}

class RecurringTileState extends State<RecurringTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final repo = context.read<RecurringRepository>();
    final isPaused = !plan.isActive;
    final nextDate = RecurringService.nextScheduledDate(plan);
    final nextStr = nextDate == null ? '—' : '${nextDate.month}/${nextDate.day}';

    // 扣款日描述，e.g. "每月 5, 20 日"
    final dayStr = '每月 ${plan.dayOfMonth.join(", ")} 日';

    return Opacity(
      opacity: isPaused ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _expanded
                  ? AppColors.primary
                  : AppColors.border,
            ),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4, offset: const Offset(0, 1),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container( //左：股票代碼徽章
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isPaused
                          ? const Color(0xFFF0F2F5)
                          : const Color(0xFFEBF0F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        plan.symbol,
                        style: TextStyle(
                          fontSize: plan.symbol.length > 4 ? 9 : 11,
                          fontWeight: FontWeight.w700,
                          color: isPaused
                              ? AppColors.textMuted
                              : const Color(0xFF4A6FA5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  //中：名稱、頻率、暫停標籤
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                plan.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isPaused
                                      ? AppColors.textMuted
                                      : const Color(0xFF1A1F2E)
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPaused) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '暫停',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE07B20),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$dayStr  ·  ${AppFmt.num(plan.amountPerTime)} 元/次',
                          style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column( //右：月金額 + 下次日期 + 選單
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${AppFmt.num(plan.monthlyAmount)}/月',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isPaused
                              ? AppColors.textMuted
                              : const Color(0xFF4A6FA5),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isPaused ? '—' : '下次：$nextStr',
                        style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: const Icon(
                        Icons.expand_more,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InfoItem(
                    label: '備註',
                    value: plan.note?.isNotEmpty == true ? plan.note! : '-',
                  ),
                ),
                ExpandedActions(
                  extraActions: [ // 暫停/恢復
                    Expanded(
                      child: GestureDetector(
                        onTap: () => repo.toggleActive(plan),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined,
                                size: 14,
                                color: const Color(0xFFE07B20),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPaused ? '恢復' : '暫停',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE07B20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}