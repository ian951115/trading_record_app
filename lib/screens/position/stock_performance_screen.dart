//個股績效頁面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/stock_performance.dart';
import '../../repositories/trade_repository.dart';
import '../../services/calc/position_service.dart';
import '../../widgets/common/app_filter_chip.dart';
import '../../widgets/common/hero_card.dart';
import '../../widgets/common/stats_strip.dart';

class StockPerformanceScreen extends StatefulWidget {
  const StockPerformanceScreen({super.key});
  @override
  State<StockPerformanceScreen> createState() => _StockPerformanceScreenState();
}

enum _PerfFilter {all, open, closed, profit, loss}

class _StockPerformanceScreenState extends State<StockPerformanceScreen> {
  _PerfFilter _filter = _PerfFilter.all;

  List<StockPerformance> _applyFilter(List<StockPerformance> all) {
    return switch (_filter) {
      _PerfFilter.all => all,
      _PerfFilter.open => all.where((p) => p.isOpen).toList(),
      _PerfFilter.closed => all.where((p) => !p.isOpen).toList(),
      _PerfFilter.profit => all.where((p) => p.totalRealizedPnL > 0).toList(),
      _PerfFilter.loss => all.where((p) => p.totalRealizedPnL < 0).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TradeRepository>();
    final trades = repo.getAllTrades();
    final allPerfs = buildPerformances(trades);
    final filtered = _applyFilter(allPerfs);

    final totalRealized = allPerfs.fold(0.0, (s, p) => s + p.totalRealizedPnL);
    final winPerfs = allPerfs.where((p) => p.totalSellCount > 0);
    final overallWinRate = winPerfs.isEmpty
        ? 0.0
        : winPerfs.map((p) => p.winRate).reduce((a,b) => a + b) / winPerfs.length;

    // 深藍背景上的主數值顏色
    final totalPnlOnDark = totalRealized >= 0
        ? const Color(0xFFFFD6D4)
        : const Color(0xFFB8F0D0);

    return Scaffold(
      appBar: AppBar(title: const Text('個股績效')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: HeroCard(
              title: '總已實現損益',
              mainValue: Text(
                AppFmt.pnl(totalRealized),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: totalPnlOnDark,
                  letterSpacing: -0.5,
                ),
              ),
              stats: [
                HeroStat(label: '交易股票數', value: '${allPerfs.length}'),
                HeroStat(
                  label: '整體勝率',
                  value: '${(overallWinRate*100).toStringAsFixed(0)}%',
                ),
                HeroStat(
                  label: '仍持有',
                  value: '${allPerfs.where((p)=>p.isOpen).length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding( //Stats strip
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: StatsStrip(
              cells: [
                StatCell(
                  label: '總買入',
                  value: AppFmt.num(allPerfs.fold(
                    0.0, (s, p) => s + p.totalBuyAmount),
                  ),
                ),
                StatCell(
                  label: '總賣出',
                  value: AppFmt.num(allPerfs.fold(
                    0.0, (s, p) => s + p.totalSellAmount),
                  ),
                ),
                StatCell(
                  label: '平均持有天數',
                  value: () {
                    final withDays = allPerfs
                        .where((p) => p.holdingDays != null)
                        .toList();
                    if (withDays.isEmpty) return '—';
                    final avg = withDays.fold(0, (s, p) => s + p.holdingDays!) / withDays.length;
                    return '${avg.round()} 天';
                  } (),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child:  SingleChildScrollView( //Filter chips
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AppFilterChip(
                  label:'全部',
                  isActive: _filter == _PerfFilter.all,
                  onTap: () => setState(() => _filter = _PerfFilter.all),
                ),
                AppFilterChip(
                  label:'持有中',
                  isActive: _filter == _PerfFilter.open,
                  onTap: () => setState(() => _filter = _PerfFilter.open),
                ),
                AppFilterChip(
                  label:'已平倉',
                  isActive: _filter == _PerfFilter.closed,
                  onTap: () => setState(() => _filter = _PerfFilter.closed),
                ),
                AppFilterChip(
                  label:'獲利 ↑',
                  isActive: _filter == _PerfFilter.profit,
                  onTap: () => setState(() => _filter = _PerfFilter.profit),
                ),
                AppFilterChip(
                  label:'虧損 ↓',
                  isActive: _filter == _PerfFilter.loss,
                  onTap: () => setState(() => _filter = _PerfFilter.loss),
                ),
              ],
            ),
          ),
          ),
          Expanded( //List
            child: filtered.isEmpty
              ? const Center(
                child: Text(
                  '沒有符合的紀錄',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _)=> const SizedBox(height: 8),
                  itemBuilder: (context, i) => _PerfTile(perf: filtered[i]),
              ),
          ),
        ],
      ),
    );
  }
}

class _PerfTile extends StatefulWidget { //績效卡片
  final StockPerformance perf;
  const _PerfTile({required this.perf});
  @override
  State<_PerfTile> createState() => _PerfTileState();
}

class _PerfTileState extends State<_PerfTile> {
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
          color: isExpanded ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? const Color(0xFFC5D4EC)
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
                          child: _DItem(
                            label: '買入成本',
                            value: AppFmt.num(p.totalBuyAmount),
                          ),
                        ),
                        Expanded(
                          child: _DItem(
                            label: '賣出收入',
                            value: AppFmt.num(p.totalSellAmount),
                          ),
                        ),
                        Expanded(
                          child: _DItem(
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
                          child: _DItem(
                            label: '持有天數',
                            value: p.holdingDays != null
                                ? '${p.holdingDays} 天'
                                : '—',
                          ),
                        ),
                        Expanded(
                          child: _DItem(
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
                          child: _DItem(
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

class _DItem extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _DItem({
    required this.label,
    required this.value,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize:10, color:AppColors.textMuted),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontSize:12,
          fontWeight:FontWeight.w600,
          color: valueColor ?? AppColors.textPrimary,
        ),
      ),
    ],
  );
}