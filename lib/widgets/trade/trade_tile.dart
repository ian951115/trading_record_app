//交易明細顯示元件
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../common/info_item.dart';
import '../../models/trade.dart';

class TradeTile extends StatefulWidget {
  final Trade trade;
  const TradeTile({
    super.key,
    required this.trade,
  });

  @override
  State<TradeTile> createState() => _TradeTileState();
}

class _TradeTileState extends State<TradeTile> {
  bool isExpanded = false;
  final formatter = NumberFormat('#,###');

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
        ? '-${formatter.format(trade.buyCost.toInt())}'
        : '+${formatter.format(trade.sellIncome.toInt())}';

    // 右側損益（只有賣出才顯示，買入顯示 --）
    // 注意：這裡用 netAmount 是暫時的，
    // 之後接真實損益資料時再替換
    final pnlText = isBuy ? '--' : null;
    final pnlColor = trade.netAmount >= 0
        ? const Color(0xFFE8504A)
        : const Color(0xFF3D9E6B);

    return GestureDetector(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150), //顏色轉變時間
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded
              ? const Color(0xFFEBF0F8)
              : Colors.white,
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
                          color: Color(0xFF9AA3B2)
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
                      pnlText ?? '+${formatter.format(trade.netAmount.toInt())}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: pnlText != null
                            ? const Color(0xFF9AA3B2)
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
                    color: Color(0xFF9AA3B2),
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
                            value: formatter.format(trade.amount.toInt()),
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '手續費',
                            value: formatter.format(trade.fee.floor()),
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '交易稅',
                            value: formatter.format(trade.tax.floor()),
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