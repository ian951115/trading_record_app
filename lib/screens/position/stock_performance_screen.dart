//個股績效頁面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/stock_performance.dart';
import '../../repositories/trade_repository.dart';
import '../../services/calc/position_service.dart';
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
      _PerfFilter.open =>
        all.where((p) => p.isOpen).toList(),
      _PerfFilter.closed =>
        all.where((p) => !p.isOpen).toList(),
      _PerfFilter.profit =>
        all.where((p) => p.totalRealizedPnL > 0).toList(),
      _PerfFilter.loss =>
        all.where((p) => p.totalRealizedPnL < 0).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TradeRepository>();
    final trades = repo.getAllTrades();
    final formatter = NumberFormat('#,###');
    final allPerfs = buildPerformances(trades);
    final filtered = _applyFilter(allPerfs);

    final totalRealized = allPerfs.fold(0.0, (s, p) => s + p.totalRealizedPnL);
    final winPerfs = allPerfs.where((p) => p.totalSellCount > 0);
    final overallWinRate = winPerfs.isEmpty
        ? 0.0
        : winPerfs.map((p) => p.winRate).reduce((a,b) => a + b) / winPerfs.length;

    return Scaffold(
      appBar: AppBar(title: const Text('個股績效')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14,12,14,0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3D5A8A),Color(0xFF4A6FA5)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '總已實現損益',
                  style: TextStyle(
                    fontSize:10,
                    color:Colors.white60,
                    letterSpacing:1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (totalRealized >= 0 ? '+' : '') +
                      formatter.format(totalRealized.toInt()),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: totalRealized >= 0
                        ? const Color(0xFFFFD6D4)
                        : const Color(0xFFB8F0D0),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _HStat(
                      label: '交易股票數',
                      value: '${allPerfs.length}',
                    ),
                    _HDivider(),
                    _HStat(
                      label: '整體勝率',
                      value: '${(overallWinRate*100).toStringAsFixed(0)}%',
                    ),
                    _HDivider(),
                    _HStat(
                      label: '仍持有',
                      value: '${allPerfs.where((p)=>p.isOpen).length}',
                    ),
                  ],
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
                  value: formatter.format(allPerfs.fold(
                    0.0, (s, p) => s + p.totalBuyAmount).toInt(),
                  ),
                ),
                StatCell(
                  label: '總賣出',
                  value: formatter.format(allPerfs.fold(
                    0.0, (s, p) => s + p.totalSellAmount).toInt(),
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
          SingleChildScrollView( //Filter chips
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                _FilterChip(
                  label:'全部',
                  isActive: _filter == _PerfFilter.all,
                  onTap: () => setState(() => _filter = _PerfFilter.all),
                ),
                _FilterChip(
                  label:'持有中',
                  isActive: _filter == _PerfFilter.open,
                  onTap: () => setState(() => _filter = _PerfFilter.open),
                ),
                _FilterChip(
                  label:'已平倉',
                  isActive: _filter == _PerfFilter.closed,
                  onTap: () => setState(() => _filter = _PerfFilter.closed),
                ),
                _FilterChip(
                  label:'獲利 ↑',
                  isActive: _filter == _PerfFilter.profit,
                  onTap: () => setState(() => _filter = _PerfFilter.profit),
                ),
                _FilterChip(
                  label:'虧損 ↓',
                  isActive: _filter == _PerfFilter.loss,
                  onTap: () => setState(() => _filter = _PerfFilter.loss),
                ),
              ],
            ),
          ),
          Expanded( //List
            child: filtered.isEmpty
              ? const Center(
                child: Text(
                  '沒有符合的紀錄',
                  style: TextStyle(color: Color(0xFF9AA3B2)),
                ),
              )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __)=> const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                    _PerfTile(
                      perf: filtered[i],
                      formatter: formatter,
                    ),
              ),
          ),
        ],
      ),
    );
  }
}

class _HStat extends StatelessWidget { //Hero小元件
  final String label, value;
  const _HStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 9, color: Colors.white60),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ],
  ));
}

class _HDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width:1, height:28, color:Colors.white24,
    margin: const EdgeInsets.symmetric(horizontal:4));
}

class _FilterChip extends StatelessWidget { //篩選Chip
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label, required this.isActive,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4A6FA5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive
              ? const Color(0xFF4A6FA5)
              : const Color(0xFFE4E7ED)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive
              ? Colors.white
              : const Color(0xFF5A6375),
          ),
        ),
      ),
    );
  }
}

class _PerfTile extends StatefulWidget { //績效卡片
  final StockPerformance perf;
  final NumberFormat formatter;
  const _PerfTile({
    required this.perf, required this.formatter,
  });
  @override
  State<_PerfTile> createState() => _PerfTileState();
}

class _PerfTileState extends State<_PerfTile> {
  bool isExpanded = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.perf;
    final f = widget.formatter;
    final pnlColor = p.totalRealizedPnL >= 0
        ? const Color(0xFFE8504A)
        : const Color(0xFF3D9E6B);
    final pnlText = (p.totalRealizedPnL >= 0 ? '+' : '') +
        f.format(p.totalRealizedPnL.toInt());

    return GestureDetector(
      onTap: () => setState(() => isExpanded =! isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded
              ? const Color(0xFFEBF0F8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isExpanded
              ? const Color(0xFFC5D4EC)
              : const Color(0xFFE4E7ED)),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4, offset: const Offset(0, 1),
          )],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container( //左側方格
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: p.isOpen
                        ? const Color(0xFFEBF0F8)
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
                        ? const Color(0xFF4A6FA5)
                        : const Color(0xFF9AA3B2))),
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
                              color: Color(0xFF1A1F2E),
                            ),
                          ),
                          if (p.isOpen) ...[ //持有中顯示
                            const SizedBox(width:6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal:6, vertical:1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF0F8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '持有中',
                                style: TextStyle(
                                  fontSize:9,
                                  fontWeight:FontWeight.w600,
                                  color:Color(0xFF4A6FA5),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text( //第二排
                        '買 ${p.totalBuyCount} 次 · 賣 ${p.totalSellCount} 次'
                        ' · 勝率 ${(p.winRate*100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize:11, color:Color(0xFF9AA3B2)),
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
                        color:Color(0xFF9AA3B2),
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
                            value: f.format(p.totalBuyAmount.toInt()),
                          ),
                        ),
                        Expanded(
                          child: _DItem(
                            label: '賣出收入',
                            value: f.format(p.totalSellAmount.toInt()),
                          ),
                        ),
                        Expanded(
                          child: _DItem(
                            label: '總費用',
                            value: f.format(p.totalFee.toInt()),
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
                                ? const Color(0xFFE8504A)
                                : const Color(0xFF3D9E6B),
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
                              style: TextStyle(fontSize:10, color:Color(0xFF9AA3B2)),
                            ),
                            Text( //進度條右上
                              p.totalSellCount == 0
                                ? '尚無賣出紀錄'
                                : '${p.winCount}/${p.totalSellCount}',
                              style: const TextStyle(
                                fontSize:10,
                                color:Color(0xFF9AA3B2),
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
                            backgroundColor: const Color(0xFFF0F2F5),
                            valueColor: AlwaysStoppedAnimation(
                              p.winRate >= 0.5
                                  ? const Color(0xFFE8504A)
                                  : const Color(0xFF3D9E6B),
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
        style: const TextStyle(fontSize:10, color:Color(0xFF9AA3B2)),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontSize:12,
          fontWeight:FontWeight.w600,
          color: valueColor ?? const Color(0xFF1A1F2E),
        ),
      ),
    ],
  );
}
