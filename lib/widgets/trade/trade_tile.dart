//交易明細顯示元件
import 'package:flutter/material.dart';
import '../common/info_item.dart';
import '../../models/trade.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';

class TradeTile extends StatefulWidget {
  final Trade trade;
  final double? realizedPnL;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TradeTile({
    super.key,
    required this.trade,
    this.realizedPnL,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TradeTile> createState() => _TradeTileState();
}

class _TradeTileState extends State<TradeTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final trade = widget.trade;
    final isBuy = trade.type == TradeType.buy;

    final badgeColor = isBuy //左側徽章顏色
        ? const Color(0xFFEBF0F8)
        : const Color(0xFFFFF3E0);
    final badgeTextColor = isBuy
        ? const Color(0xFF4A6FA5)
        : const Color(0xFFE07B20);

    final netText = isBuy //右側應收付金額（無顏色）
        ? '-${AppFmt.num(trade.buyCost)}'
        : '+${AppFmt.num(trade.sellIncome)}';

    final pnl = widget.realizedPnL;
    final pnlDisplay = isBuy
        ? '--'
        : (pnl != null ? '${pnl >= 0 ? '+' : ''}${AppFmt.num(pnl)}' : '--');
    final pnlColor = AppColors.pnl(pnl ?? 0);

    return GestureDetector(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150), //顏色轉變時間
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:  Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all( //邊框
            color: isExpanded
                ? const Color(0xFFC5D4EC)
                : const Color(0xFFE4E7ED),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── 主要列 ──────────────────────
            Row(
              children: [
                Container( //左側：買/賣 徽章
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isBuy ? '買' : '賣',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: badgeTextColor,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded( //中間：交易資訊
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trade.name} (${trade.symbol})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A1F2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trade.date.year}/${trade.date.month.toString().padLeft(2,'0')}/${trade.date.day.toString().padLeft(2,'0')} '
                        '${trade.quantity} 股 @ ${trade.price}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Column( //右側：應收付 + 損益
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text( //上排：應收付（無顏色）
                      netText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1F2E),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text( //下排：損益（賣出才有）或 --
                      pnlDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (isBuy || pnl == null)
                            ? AppColors.textMuted
                            : pnlColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),

                AnimatedRotation( //展開箭頭
                  turns: isExpanded ? 0.5 : 0, //value*2*pi
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.expand_more,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            // ── 展開區 ──────────────────────
            AnimatedCrossFade( //展開資訊
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InfoItem(
                            label: '價金',
                            value: AppFmt.num(trade.amount),
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '手續費',
                            value: AppFmt.num(trade.fee),
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '交易稅',
                            value: AppFmt.num(trade.tax), //原本是.floor()，請確認不會出錯
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InfoItem(
                            label: '備註',
                            value: trade.note?.isNotEmpty == true
                                ? trade.note!
                                : '-',
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '策略標籤',
                            value: trade.tags.isNotEmpty
                                ? trade.tags.join('、')
                                : '-',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onEdit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF0F8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: Color(0xFF4A6FA5),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '編輯',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4A6FA5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onDelete,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF0EF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 14,
                                    color: AppColors.profit,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '刪除',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.profit,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 150),
            ),
          ],
        ),
      ),  
    );
  }
}