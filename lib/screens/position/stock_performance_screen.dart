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
import '../../widgets/tiles/stock_performance_tile.dart';

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
              title: '已實現損益',
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
                  itemBuilder: (context, i) => PerfTile(perf: filtered[i]),
              ),
          ),
        ],
      ),
    );
  }
}