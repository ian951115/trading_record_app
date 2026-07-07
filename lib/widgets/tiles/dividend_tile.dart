//股利顯示元件
import 'package:flutter/material.dart';
import '../../models/dividend.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../widgets/common/expanded_actions.dart';

class DividendTile extends StatefulWidget { //股利卡片
  final Dividend dividend;
  final VoidCallback onDelete, onEdit;

  const DividendTile({
    super.key,
    required this.dividend,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<DividendTile> createState() => DividendTileState();
}

class DividendTileState extends State<DividendTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.dividend;
    final isCash = d.type == DividendType.cash;
    final dateStr = '${d.date.year}/'
        '${d.date.month.toString().padLeft(2,'0')}/'
        '${d.date.day.toString().padLeft(2,'0')}';

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
            color: Colors.black.withValues(alpha:0.04),
            blurRadius:4,
            offset: const Offset(0,1),
          )],
        ),
        child: Column(
          children: [
            // ── 主行（永遠顯示）──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child:  Row(
                children: [
                  Container( //左側圖示
                    width:36, height:36,
                    decoration: BoxDecoration(
                      color: isCash
                          ? AppColors.lossBg
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCash ? Icons.payments_outlined : Icons.trending_up,
                      size: 18,
                      color: isCash
                          ? AppColors.loss
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded( //中間資訊
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text( //名稱及股號
                              '${d.name} (${d.symbol})',
                              style: const TextStyle(
                                fontSize:13,
                                fontWeight:FontWeight.w700,
                                color:AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container( //分類標籤
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isCash
                                    ? AppColors.lossBg
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCash ? '現金' : '股票',
                                style: TextStyle(
                                  fontSize:9,
                                  fontWeight:FontWeight.w700,
                                  color: isCash ? AppColors.loss : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text( //第二排日期及數量
                          isCash
                            ? '$dateStr · 每股 ${d.cashAmount / (d.shareAmount > 0 ? d.shareAmount : 1)} 元'
                            : '$dateStr · 配股 ${d.shareAmount} 股',
                          style: const TextStyle(fontSize:11, color:AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column( //右側金額
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isCash ? AppFmt.pnl(d.cashAmount) : '+${d.shareAmount} 股',
                        style: TextStyle(
                          fontSize:14,
                          fontWeight:FontWeight.w700,
                          color: isCash ? AppColors.loss : AppColors.primary,
                        ),
                      ),
                      if (isCash && d.netCashAmount != d.cashAmount)
                      Text(
                        '淨 ${AppFmt.num(d.netCashAmount)}',
                        style: const TextStyle(
                          fontSize:10,
                          color:AppColors.textMuted,
                        ),
                      ),
                    ],
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
              if (d.note != null && d.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_outlined,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          d.note!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
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