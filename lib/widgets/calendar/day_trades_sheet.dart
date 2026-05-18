//點擊日期彈出的交易明細Bottom Sheet元件
import 'package:flutter/material.dart';
import '../../models/trade.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';

class DayTradesSheet extends StatelessWidget {
  final DateTime date;
  final List<Trade> trades;
  final double pnl;
  final ScrollController scrollController;

  const DayTradesSheet({
    super.key,
    required this.date,
    required this.trades,
    required this.pnl,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekday = weekdays[date.weekday - 1];
    final dateStr = '${date.year} 年 ${date.month} 月 ${date.day} 日（$weekday）';

    final pnlColor = AppColors.pnl(pnl);

    final pnlText = pnl == 0 ? '—' : AppFmt.pnl(pnl);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Center( //拖曳把手
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE4E7ED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${trades.length} 筆交易',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '當日損益',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pnlText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: pnlColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          if (trades.isEmpty) //交易列表
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '這天沒有交易紀錄',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...trades.map((t) => _TradeTile(trade: t)),
        ],
      ),
    );
  }
}

class _TradeTile extends StatelessWidget {
  final Trade trade;

  const _TradeTile({required this.trade,});

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.type == TradeType.buy;
    final badgeColor = isBuy
        ? const Color(0xFFEBF0F8)
        : const Color(0xFFFFF3E0);
    final badgeTextColor = isBuy
        ? const Color(0xFF4A6FA5)
        : const Color(0xFFE07B20);

    final netText = isBuy
        ? AppFmt.pnl(trade.buyCost)
        : AppFmt.pnl(trade.sellIncome);
    final neyColor = isBuy
        ? AppColors.loss
        : AppColors.profit;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7ED)),
      ),
      child: Row(
        children: [
          Container( //買/賣 徽章
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              isBuy ? '買' : '賣',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded( //名稱 + 數量
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trade.name} (${trade.symbol})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${trade.quantity} 股 @ ${trade.price}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text( //應收付
            netText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: neyColor,
            ),
          ),
        ],
      ),
    );
  }
}