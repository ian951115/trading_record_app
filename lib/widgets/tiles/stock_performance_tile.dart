//個股績效顯示元件
import 'package:flutter/material.dart';
import '../../models/stock_performance.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../widgets/common/info_item.dart';

class PerfTile extends StatefulWidget { //績效卡片
  final StockPerformance perf;
  const PerfTile({super.key, required this.perf});
  @override
  State<PerfTile> createState() => PerfTileState();
}

class PerfTileState extends State<PerfTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.perf;
    final pnlColor = AppColors.pnl(p.totalRealizedPnL);
    final pnlText = AppFmt.pnl(p.totalRealizedPnL);

    return GestureDetector(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? AppColors.primary
                : AppColors.border
          ),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container( //左側方格
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: p.isOpen
                        ? AppColors.primaryLight
                        : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.symbol,
                    style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: p.isOpen
                        ? AppColors.primary
                        : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded( //中間資訊
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row( //第一排:名稱及持有狀態
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (p.isOpen) ...[ //持有中顯示
                            const SizedBox(width:6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal:6, vertical:1),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '持有中',
                                style: TextStyle(
                                  fontSize:9,
                                  fontWeight:FontWeight.w600,
                                  color:AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text( //第二排
                        '買 ${p.totalBuyCount} 次 · 賣 ${p.totalSellCount} 次'
                        ' · 勝率 ${(p.winRate*100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize:11, color:AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column( //右側損益及翻轉鈕
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pnlText,
                      style: TextStyle(
                        fontSize:15,
                        fontWeight:FontWeight.w700,
                        color: pnlColor,
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds:150),
                      child: const Icon(
                        Icons.expand_more,
                        size:18,
                        color:AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AnimatedCrossFade( //展開區域
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    Row( //第一排：買入成本、賣出收入、已實現損益
                      children: [
                        Expanded(
                          child: InfoItem(
                            label: '買入成本',
                            value: AppFmt.num(p.totalBuyAmount),
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '賣出收入',
                            value: AppFmt.num(p.totalSellAmount),
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '總費用',
                            value: AppFmt.num(p.totalFee),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row( //第二排：持有天數、報酬率、交易次數
                      children: [
                        Expanded(
                          child: InfoItem(
                            label: '持有天數',
                            value: p.holdingDays != null
                                ? '${p.holdingDays} 天'
                                : '—',
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '報酬率',
                            value: p.totalBuyAmount == 0
                                ? '—'
                                : '${p.totalRealizedPnL >= 0 ? '+' : ''}'
                                  '${(p.totalRealizedPnL / p.totalBuyAmount * 100).toStringAsFixed(1)}%',
                            valueColor: p.totalRealizedPnL >= 0
                                ? AppColors.profit
                                : AppColors.loss,
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '交易次數',
                            value: '買${p.totalBuyCount} 賣${p.totalSellCount}',
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column( //勝率條
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text( //進度條左上
                              '勝率',
                              style: TextStyle(fontSize:10, color:AppColors.textMuted),
                            ),
                            Text( //進度條右上
                              p.totalSellCount == 0
                                ? '尚無賣出紀錄'
                                : '${p.winCount}/${p.totalSellCount}',
                              style: const TextStyle(
                                fontSize:10,
                                color:AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: p.winRate,
                            minHeight: 6,
                            backgroundColor: AppColors.scaffoldBg,
                            valueColor: AlwaysStoppedAnimation(
                              p.winRate >= 0.5
                                  ? AppColors.profit
                                  : AppColors.loss,
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