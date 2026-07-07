//資金紀錄顯示元件
import 'package:flutter/material.dart';
import '../../models/cash_flow.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../widgets/common/expanded_actions.dart';

class CashFlowTile extends StatefulWidget {
  final CashFlow flow;
  final VoidCallback onDelete, onEdit;
  const CashFlowTile({
    super.key,
    required this.flow,
    required this.onDelete,
    required this.onEdit
  });

  @override
  State<CashFlowTile> createState() => CashFlowTileState();
}

class CashFlowTileState extends State<CashFlowTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    final isDeposit = flow.type == CashFlowType.deposit;
    final dateStr = '${flow.date.year}/'
        '${flow.date.month.toString().padLeft(2,'0')}/'
        '${flow.date.day.toString().padLeft(2,'0')}';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
          children: [
            // ── 主行（永遠顯示）──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container( //左側圖示
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isDeposit
                          ? AppColors.lossBg
                          : AppColors.profitBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDeposit
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 18,
                      color: isDeposit
                          ? AppColors.loss
                          : AppColors.profit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded( //中間：類型 + 日期
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDeposit ? '入金' : '提領',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          flow.note?.isNotEmpty == true
                              ? '$dateStr・${flow.note}'
                              : dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text( //右側金額
                    isDeposit
                        ? '+${AppFmt.num(flow.amount)}'
                        : '-${AppFmt.num(flow.amount)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDeposit
                          ? AppColors.loss
                          : AppColors.profit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation( //展開箭頭
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
  
            // ── 展開行（編輯/刪除按鈕）──────────
            if (_expanded) ...[
              Divider(
                height: 1,
                color: AppColors.border,
                indent: 14,
                endIndent: 14,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: ExpandedActions(
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                )
              ),
            ],
          ],
        ),
      ),
    );
  }
}