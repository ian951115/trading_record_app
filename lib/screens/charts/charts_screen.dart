//各式圖表
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/trade.dart';
import '../../models/position.dart';
import '../../models/cash_flow.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/cash_flow_repository.dart';
import '../../services/calc/chart_service.dart';
import '../../services/calc/position_service.dart';
import '../../widgets/common/stats_strip.dart';

// 圖表頁面顏色常數
const _chartColors = [
  Color(0xFF4A6FA5), Color(0xFFE8504A),
  Color(0xFF3D9E6B), Color(0xFFE07B20),
  Color(0xFF9B59B6), Color(0xFF1ABC9C),
];

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});
  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  String _assetRange = '1m'; // 1m / 3m / 1y / all
  int _monthlyYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tradeRepo = context.watch<TradeRepository>();
    final cashRepo = context.watch<CashFlowRepository>();
    final trades = tradeRepo.getAllTrades();
    final cashFlows = cashRepo.getAllFlows();
    final posResult = buildPositions(trades);
    final openPositions = posResult.positions.where((p) => p.quantity > 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('各式圖表')),
      body: Column(
        children: [
          TabBar( //Tab列
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF4A6FA5), //選中分頁顏色
            unselectedLabelColor: AppColors.textMuted, //其他分頁顏色
            indicatorColor: const Color(0xFF4A6FA5), //選中分頁指示器
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700
            ),
            tabs: const [
              Tab(text: '總資產'),
              Tab(text: '每月損益'),
              Tab(text: '持股佔比'),
              Tab(text: '策略績效'),
           ],
         ),
         const Divider(height: 1),
          Expanded( //內容
            child: TabBarView(
              controller: _tabController,
              children: [
                _AssetTab(
                  trades: trades,
                  cashFlows: cashFlows,
                  range: _assetRange,
                  onRangeChanged: (r) => setState(() => _assetRange = r),
                ),
                _MonthlyTab(
                  trades: trades,
                  year: _monthlyYear,
                  onYearChanged: (y) => setState(() => _monthlyYear = y),
                ),
                _PieTab(openPositions: openPositions),
                _StrategyTab(
                  trades: trades,
                  tradePnLMap: posResult.tradePnLMap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// A  總資產折線圖
// ════════════════════════════════════════════════════════════
class _AssetTab extends StatefulWidget {
  final List<Trade> trades;
  final List<CashFlow> cashFlows;
  final String range;
  final ValueChanged<String> onRangeChanged;
  const _AssetTab({
    required this.trades, required this.cashFlows,
    required this.range, required this.onRangeChanged,
  });
  @override
  State<_AssetTab> createState() => _AssetTabState();
}

class _AssetTabState extends State<_AssetTab> {
  // ──三條線 toggle state ──
  bool _showTotal = true;
  bool _showStock = true;
  bool _showCash  = true;
 
  // ──點選資料點 ──
  AssetDataPoint? _touchedPoint;

  List<AssetDataPoint> _filterByRange(List<AssetDataPoint> data) { //時間篩選
    if (widget.range == 'all') return data;
    final now = DateTime.now();
    final cutoff = switch (widget.range) {
      '1m' => DateTime(now.year, now.month - 1, now.day),
      '3m' => DateTime(now.year, now.month - 3, now.day),
      '1y' => DateTime(now.year - 1, now.month, now.day),
      _ => DateTime(1961),
    };
    return data.where((d) => !d.date.isBefore(cutoff)).toList();
  }

  // ──X 軸日期顯示邏輯 ──
  bool _shouldShowXLabel(DateTime date, String range, bool isFirst) {
    // 第一個點永遠顯示
    if (isFirst) return true;
    return switch (range) {
      '1m'  => date.weekday == DateTime.monday,
      '3m'  => date.weekday == DateTime.monday &&
                (date.day <= 7 || (date.day >= 15 && date.day <= 21)),
      '1y'  => date.day == 1,
      'all' => date.day == 1,
      _     => date.day == 1,
    };
  }

  // 是否需要顯示年份（範圍跨年時）
  bool _isMultiYear(List<AssetDataPoint> data) {
    if (data.length < 2) return false;
    return data.first.date.year != data.last.date.year;
  }
 
  String _xLabel(DateTime d, bool multiYear) {
    if (multiYear && d.day == 1) {
      // 每月一日且跨年：顯示 YY/M
      return '${d.year % 100}/${d.month}';
    }
    return '${d.month}/${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final allData = ChartService.buildAssetHistory(
      trades: widget.trades, cashFlows: widget.cashFlows);
    final data = _filterByRange(allData);

    if (data.isEmpty) {
      return const Center(
        child: Text(
          '尚無資料',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    // ──單點保護 ──
    double minAsset, maxAsset;
    if (data.length == 1) {
      minAsset = data[0].totalAsset * 0.9;
      maxAsset = data[0].totalAsset * 1.1;
    } else {
      maxAsset = data.map((d) => d.totalAsset).reduce(max); //找max
      minAsset = data.map((d) => d.totalAsset).reduce(min); //找min
    }

    final current = data.last.totalAsset;
    final first = data.first.totalAsset;
    final change = current - first;
    final changePct = first == 0 ? 0.0 : change / first * 100; //範圍內資產變化率
    final changeColor = change >= 0
        ? AppColors.profit
        : AppColors.loss;

    // ──Y 軸單位自動判斷 ──
    final useWan = (maxAsset / 10000) >= 1;
 
    final multiYear = _isMultiYear(data);
 
    // ──依 toggle bool 組合 lineBarsData ──
    final bars = <LineChartBarData>[];

    LineChartBarData _makeLine({
      required List<FlSpot> spots,
      required Color color,
    }) {
      return LineChartBarData(
        spots: spots,
        isCurved: false,
        color: color,
        barWidth: 2,
        dotData: FlDotData(
          show: true,
          checkToShowDot: (spot, _) =>
              _touchedPoint != null &&
              spot.x.toInt() < data.length &&
              data[spot.x.toInt()].date == _touchedPoint!.date,
          getDotPainter: (_, _, _, _) => FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.01),
            ],
          ),
        ),
      );
    }

    //建立曲線資料點
    if (_showTotal) { //總資產曲線
      bars.add(
        _makeLine(
          spots: data.asMap().entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.totalAsset))
              .toList(),
          color: const Color(0xFF4A6FA5),
        ),
      );
    }
    if (_showStock) {
      bars.add(
        _makeLine(
          spots: data.asMap().entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.marketValue))
              .toList(),
          color: AppColors.profit,
        ),
      );
    }
    if (_showCash) { //現金曲線
      bars.add(
        _makeLine(
          spots: data.asMap().entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.cash))
              .toList(),
          color: AppColors.loss,
        ),
      );
    }
    if (bars.isEmpty) { //至少保留一條線（全關時強制顯示總資產）
      bars.add(
        _makeLine(
          spots: data.asMap().entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.totalAsset))
              .toList(),
          color: const Color(0xFF4A6FA5),
        ),
      );
    }

    // Y 軸範圍（取所有顯示線的 min/max）
    double chartMinY = minAsset * 0.95;
    double chartMaxY = maxAsset * 1.05;
    if (_showStock || _showCash) {
      final allVals = [
        if (_showTotal) ...data.map((d) => d.totalAsset),
        if (_showStock) ...data.map((d) => d.marketValue),
        if (_showCash)  ...data.map((d) => d.cash),
      ];
      if (allVals.isNotEmpty) {
        chartMinY = allVals.reduce(min) * 0.95;
        chartMaxY = allVals.reduce(max) * 1.05;
      }
    }

    // 確認有沒有標籤應該顯示（若整段沒有 1 日則 fallback 到第一個點）
    final hasAnyLabel = data.any((d) =>
        _shouldShowXLabel(d.date, widget.range, d == data.first));

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _RangeChips( //時間範圍選擇
          options: const ['1m','3m','1y','all'],
          labels: const ['1月','3月','1年','全部'],
          selected: widget.range,
          onChanged: widget.onRangeChanged,
        ),
        const SizedBox(height: 10),
        StatsStrip( //統計列
          cells: [
            StatCell(
              label: '目前總資產',
              value: AppFmt.num(current),
              valueColor: const Color(0xFF4A6FA5),
            ),
            StatCell(
              label: '期間變化',
              value: AppFmt.pnl(change),
              valueColor: changeColor,
            ),
            StatCell(
              label: '變化率',
              value: '${changePct >= 0 ? '+' : ''}'
                  '${changePct.toStringAsFixed(1)}%',
              valueColor: changeColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container( //折線圖卡片
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E7ED)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4, offset: const Offset(0, 1),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('總資產變化曲線',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E),
                ),
              ),
              const SizedBox(height: 10),
              // ── A5：Toggle 列 ──
              _LineToggle(
                showTotal: _showTotal,
                showStock: _showStock,
                showCash: _showCash,
                onToggleTotal: () => setState(() => _showTotal = !_showTotal),
                onToggleStock: () => setState(() => _showStock = !_showStock),
                onToggleCash: () => setState(() => _showCash  = !_showCash),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minY: chartMinY,
                    maxY: chartMaxY, //y軸對應的最大值
                    clipData: const FlClipData.all(), //限制在格子內
                    gridData: FlGridData( //格線設定
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFE4E7ED),
                        strokeWidth: 1, //虛線厚度
                        dashArray: [4, 4], //虛線長度
                      ),
                    ),
                    borderData: FlBorderData(show: false), //圖表邊界顯示設定
                    titlesData: FlTitlesData( //軸標題設定
                      leftTitles: AxisTitles( //左邊顯示金額
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          // ──Y 軸單位自動 ──
                          getTitlesWidget: (v, _) => Text(
                            useWan
                                ? '${(v / 10000).toStringAsFixed(0)}萬'
                                : v.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      rightTitles: AxisTitles( //右邊不顯示
                        sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles( //上方不顯示
                        sideTitles: SideTitles(showTitles: false)),
                      // ──X 軸日期邏輯 ──
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= data.length) {
                              return const SizedBox.shrink();
                            }
                            final d = data[i].date;
                            final isFirst = i == 0;
                            final show = hasAnyLabel
                                ? _shouldShowXLabel(d, widget.range, isFirst)
                                : isFirst;
                            if (!show) return const SizedBox.shrink();
                            return Text(
                              _xLabel(d, multiYear),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // ──點選更新 _touchedPoint ──
                    lineTouchData: LineTouchData( //日期對應資料方框
                      touchCallback: (event, response) { //對選取的反應
                        setState(() {
                          final x = response?.lineBarSpots?.first.x.toInt();
                          _touchedPoint = (x != null && x < data.length)
                              ? data[x]
                              : null;
                        });
                      },
                      touchTooltipData: LineTouchTooltipData( //內容
                        tooltipBgColor: const Color(0xFF1A1F2E).withValues(alpha: 0.85),
                        getTooltipItems: (spots) {
                          return spots.asMap().entries.map((e) {
                            final idx = e.key;
                            final s = e.value;
                            final i = s.x.toInt();
                            final d = i < data.length ? data[i].date : null;
                            final dateStr = (idx == 0 && d != null)
                                ? '${d.year}/${d.month}/${d.day}\n' : '';
                            return LineTooltipItem(
                              '$dateStr${AppFmt.num(s.y)}元',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: bars,
                  ),
                ),
              ),
              // ──點選展開詳細卡片 ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _touchedPoint == null
                    ? const SizedBox.shrink()
                    : _TouchDetailCard(
                      key: ValueKey(_touchedPoint!.date),
                      point: _touchedPoint!,
                      showStock: _showStock,
                      showCash: _showCash,
                    ),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ──6 格亮點卡片 ──
        _HighlightCard(data: data),
      ],
    );
  }
}

// ──三條線 Toggle Widget ──
class _LineToggle extends StatelessWidget {
  final bool showTotal, showStock, showCash;
  final VoidCallback onToggleTotal, onToggleStock, onToggleCash;
  const _LineToggle({
    required this.showTotal, required this.showStock,
    required this.showCash, required this.onToggleTotal,
    required this.onToggleStock, required this.onToggleCash,
  });

  Widget _pill(String label, Color color, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : const Color(0xFFE4E7ED)),
          color: active
              ? color.withValues(alpha: 0.08)
              : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? color : const Color(0xFFD0D5DD),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: active ? color : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill('總資產', const Color(0xFF4A6FA5), showTotal, onToggleTotal),
        const SizedBox(width: 8),
        _pill('持股市值', AppColors.profit, showStock, onToggleStock),
        const SizedBox(width: 8),
        _pill('現金', AppColors.loss, showCash, onToggleCash),
      ],
    );
  }
}

// ──點選詳細卡片 ──
class _TouchDetailCard extends StatelessWidget {
  final AssetDataPoint point;
  final bool showStock, showCash;
  const _TouchDetailCard({
    super.key,
    required this.point,
    required this.showStock,
    required this.showCash,
  });

  Widget _cell(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = point.date;
    final dateStr = '${d.year}/${d.month}/${d.day}';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7ED)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _cell('選取日期', dateStr, const Color(0xFF1A1F2E)),
          ),
          Expanded(
            child: _cell(
              '總資產',
              AppFmt.num(point.totalAsset),
              const Color(0xFF4A6FA5),
            ),
          ),
          if (showStock)
            Expanded(
              child: _cell(
                '持股市值',
                AppFmt.num(point.marketValue),
                AppColors.profit,
              ),
            ),
          if (showCash)
            Expanded(
              child: _cell(
                '現金',
                AppFmt.num(point.cash),
                AppColors.loss,
              ),
            ),
        ],
      ),
    );
  }  
}

// ──6 格亮點卡片 ──
class _HighlightCard extends StatelessWidget {
  final List<AssetDataPoint> data;
  const _HighlightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxPoint = data.reduce(
        (a, b) => a.totalAsset > b.totalAsset ? a : b);
    final minPoint = data.reduce(
        (a, b) => a.totalAsset < b.totalAsset ? a : b);

    double maxDailyGain = 0;
    double maxDailyDrop = 0;
    DateTime maxGainDate = data.first.date;
    DateTime maxDropDate = data.first.date;
    int profitDays = 0;
 
    // ──最大回撤計算 ──
    double peak = data.first.totalAsset;
    double maxDrawdown = 0;

    for (int i = 1; i < data.length; i++) {
      final change = data[i].totalAsset - data[i - 1].totalAsset;
      if (change > maxDailyGain) {
        maxDailyGain = change;
        maxGainDate = data[i].date;
      }
      if (change < maxDailyDrop) {
        maxDailyDrop = change;
        maxDropDate = data[i].date;
      }
      if (change > 0) profitDays++;
 
      peak = max(peak, data[i].totalAsset);
      if (peak > 0) {
        final dd = (peak - data[i].totalAsset) / peak * 100;
        maxDrawdown = max(maxDrawdown, dd);
      }
    }

    final totalDays = data.length - 1;
    String fmt(DateTime d) => '${d.month}/${d.day}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7ED)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📌 期間亮點',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row( //第一行
            children: [
              _HighlightItem(
                label: '最高資產',
                value: _shortFmt(maxPoint.totalAsset),
                sub: fmt(maxPoint.date),
                color: AppColors.profit,
                bgColor: const Color(0xFFFDF0EF),
              ),
              const SizedBox(width: 8),
              _HighlightItem(
                label: '最低資產',
                value: _shortFmt(minPoint.totalAsset),
                sub: fmt(minPoint.date),
                color: AppColors.loss,
                bgColor: const Color(0xFFEEF7F2),
              ),
              const SizedBox(width: 8),
              _HighlightItem(
                label: '最大單日漲幅',
                value: '+${AppFmt.num(maxDailyGain)}',
                sub: fmt(maxGainDate),
                color: const Color(0xFF4A6FA5),
                bgColor: const Color(0xFFEBF0F8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row( //第二行
            children: [
              _HighlightItem(
                label: '最大回測',
                value: '-${maxDrawdown.toStringAsFixed(1)}%',
                sub: '期間峰值',
                color: const Color(0xFFE07B20),
                bgColor: const Color(0xFFFDF8EE),
              ),
              const SizedBox(width: 8),
              _HighlightItem(
                label: '最大單日跌幅',
                value: AppFmt.num(maxDailyDrop),
                sub: fmt(maxDropDate),
                color: AppColors.loss,
                bgColor: const Color(0xFFEEF7F2),
              ),
              const SizedBox(width: 8),
              _HighlightItem(
                label: '獲利天數',
                value: totalDays == 0
                    ? '-'
                    : '$profitDays / $totalDays',
                sub: totalDays == 0
                    ? ''
                    : '${(profitDays / totalDays * 100).toStringAsFixed(0)}%',
                color: const Color(0xFF1A1F2E),
                bgColor: const Color(0xFFF2F2F2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 大數字縮短顯示（>= 10000 用「萬」）
  String _shortFmt(double v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}萬';
    return AppFmt.num(v);
  }
}

class _HighlightItem extends StatelessWidget { //亮點卡片格子
  final String label, value, sub;
  final Color color, bgColor;
  const _HighlightItem({
    required this.label, required this.value,
    required this.sub, required this.color,
    required this.bgColor,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              sub,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// B  每月損益長條圖
// ════════════════════════════════════════════════════════════
class _MonthlyTab extends StatelessWidget {
  final List<Trade> trades;
  final int year;
  final ValueChanged<int> onYearChanged;
  const _MonthlyTab({
    required this.trades, required this.year,
    required this.onYearChanged,
  });

  // ──nice round number ──
  double _niceMax(double value) { //自動尺度/級距計算
    if (value == 0) return 1;
    final mag = pow(10, (log(value.abs()) / ln10).floor()).toDouble();
    final normalized = value / mag;
    double rounded;
    if (normalized <= 1) rounded = 1;
    else if (normalized <= 1.5) rounded = 1.5;
    else if (normalized <= 2) rounded = 2;
    else if (normalized <= 2.5) rounded = 2.5;
    else if (normalized <= 3) rounded = 3;
    else if (normalized <= 5) rounded = 5;
    else rounded = 10;
    return rounded * mag;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyPnL = ChartService.buildMonthlyPnL(
      trades: trades, year: year);

    final total = monthlyPnL.values.fold(0.0, (s, v) => s + v);

    //最佳月份只考慮有賣出的月份（pnl != 0）
    final nonZeroEntries = monthlyPnL.entries
        .where((e) => e.value != 0).toList();
    final bestMonth = nonZeroEntries.isEmpty
        ? null
        : nonZeroEntries.reduce((a, b) => a.value > b.value ? a : b).key;

    //Y軸分開取最大正值和最小負值，不強制對稱
    final allValues = List.generate(12, (i) => monthlyPnL[i + 1] ?? 0.0);
    final maxVal = allValues.reduce(max);
    final minVal = allValues.reduce(min);
    final hasData = nonZeroEntries.isNotEmpty;

    // ── Y 軸自動尺度 ──
    final nicePos = (hasData && maxVal > 0) ? _niceMax(maxVal) : 100000; //+
    final double chartMaxY = nicePos * 1.05;
    final double chartMinY = minVal < 0
        ? -max(minVal.abs() * 1.3, chartMaxY * 0.08)
        : -nicePos * 0.15;
 
    // ──統一單位 ──
    final useWan = nicePos >= 10000;
    final unitLabel = useWan ? '單位：萬元' : '單位：元';

    //建立BarChart資料
    final groups = List.generate(12, (i) {
      final month = i + 1;
      final pnl = monthlyPnL[month] ?? 0.0;
      return BarChartGroupData(
        x: month,
        barRods: [
          BarChartRodData(
            toY: pnl,
            color: pnl >= 0
                ? AppColors.profit
                : AppColors.loss,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row( //年份切換
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavBtn(
              icon: Icons.chevron_left,
              onTap: () => onYearChanged(year - 1),
            ),
            const SizedBox(width: 16),
            Text('$year 年',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F2E),
              ),
            ),
            const SizedBox(width: 16),
            _NavBtn(
              icon: Icons.chevron_right,
              onTap: () => onYearChanged(year + 1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatsStrip( //統計列
          cells: [
            StatCell(
              label: '年度損益',
              value: AppFmt.pnl(total),
              valueColor: total >= 0
                  ? AppColors.profit
                  : AppColors.loss,
            ),
            StatCell(
              label: '總獲利月份',
              value: '${monthlyPnL.values.where((v) => v > 0).length} 月',
            ),
            StatCell(
              label: '最佳月份',
              value: bestMonth == null ? '—' : '$bestMonth 月',
              valueColor: bestMonth == null
                  ? null
                  : AppColors.profit,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E7ED)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4, offset: const Offset(0, 1),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '每月損益 · $year 年',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F2E),
                    ),
                  ),
                  Text(
                    unitLabel,
                    style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: chartMaxY, //y軸對應的最大值
                    minY: chartMinY,
                    barGroups: groups,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: v == 0
                            ? AppColors.textMuted
                            : const Color(0xFFE4E7ED),
                        strokeWidth: v == 0 ? 1.5 : 1, //零線加粗
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    // ── 自訂 Tooltip ──
                    barTouchData: BarTouchData( //日期對應資料方框
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: const Color(0xFF1A1F2E).withValues(alpha: 0.85),
                        getTooltipItem: (group, _, rod, _) { //內容
                          final pnl = rod.toY;
                          return BarTooltipItem(
                            '${group.x}月\n${AppFmt.pnl(pnl)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles( //底部顯示月份
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}月',
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles( //左邊顯示金額
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          getTitlesWidget: (v, meta) {
                            if (v == meta.min || v == meta.max) {
                              return const SizedBox.shrink();
                            }
                            final label = useWan
                                ? '${(v / 10000).toStringAsFixed(0)}萬'
                                : v.toStringAsFixed(0);
                            return Text(
                              label,
                              style: const TextStyle(
                                fontSize: 8,
                                color: AppColors.textMuted,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// C  持股佔比圓餅圖
// ════════════════════════════════════════════════════════════
enum _PieMode {marketValue, cost, unrealized}

class _PieTab extends StatefulWidget {
  final List<Position> openPositions;
  const _PieTab({required this.openPositions});
  @override
  State<_PieTab> createState() => _PieTabState();
}

class _PieTabState extends State<_PieTab> {
  int _selectedIndex = -1; //選中索引
 
  _PieMode _pieMode = _PieMode.marketValue; //子圖 mode
 
  // ──依 mode 取值 ──
  double _getPieValue(HoldingShare s) {
    return switch (_pieMode) {
      _PieMode.marketValue => s.marketValue,
      _PieMode.cost => s.cost,
      _PieMode.unrealized => s.unrealized,
    };
  }

  @override
  Widget build(BuildContext context) {
    final shares = ChartService.buildHoldingShares(widget.openPositions);

    if (shares.isEmpty) {
      return const Center(child: Text('目前沒有持倉',
        style: TextStyle(color: AppColors.textMuted)));
    }

    // ──unrealized 全負保護 ──
    if (_pieMode == _PieMode.unrealized) {
      final total = shares.fold(0.0, (s, h) => s + h.unrealized);
      if (total <= 0) {
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _pieModeChips(),
            const SizedBox(height: 60),
            const Center(
              child: Text('無未實現收益資料',
                style: TextStyle(
                  fontSize: 14, color: AppColors.textMuted),
              ),
            ),
          ],
        );
      }
    }

    //決定 比例/顏色/數值
    final sections = shares.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      final val = _getPieValue(s);
      final isSelected = i == _selectedIndex;
      final color = (_pieMode == _PieMode.unrealized && val < 0)
          ? const Color(0xFFB0B8C4)
          : _chartColors[i % _chartColors.length];
      return PieChartSectionData(
        value: val.abs(),
        color: color,
        radius: isSelected ? 82 : 65,
        showTitle: false,
      );
    }).toList();

    final selected = shares[_selectedIndex.clamp(0, shares.length - 1)];
    final selectedVal = _getPieValue(selected);
    final selectedColor = (_pieMode == _PieMode.unrealized && selectedVal < 0)
        ? const Color(0xFFB0B8C4)
        : _chartColors[_selectedIndex % _chartColors.length];
    final totalVal = shares.fold(0.0, (s, h) => s + _getPieValue(h).abs());
    final selectedPct = totalVal == 0
        ? 0.0 : selectedVal.abs() / totalVal * 100;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E7ED)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4, offset: const Offset(0, 1),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('當前持股佔比',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E),
                ),
              ),
              const SizedBox(height: 10),
              // ──子圖 toggle ──
              _pieModeChips(),
              const SizedBox(height: 16),
              // ──圓餅圖 + Stack 圓心 ──
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections, //區塊數據
                        sectionsSpace: 2, //區塊間格
                        centerSpaceRadius: 42, //中心圓半徑
                        // ──點選切換 ──
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (response?.touchedSection != null) {
                              setState(() {
                                _selectedIndex = response!
                                    .touchedSection!.touchedSectionIndex;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    // ──圓心資訊 ──
                    if (_selectedIndex >= 0) ...[
                      SizedBox(
                        width: 72,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              child: Text(
                                selected.symbol,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: selectedColor,
                                ),
                              ),
                            ),
                            FittedBox(
                              child: Text(
                                '${selectedPct.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: selectedColor,
                                ),
                              ),
                            ),
                            FittedBox(
                              child: Text(
                                '${AppFmt.num(selectedVal.abs())} 元',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ──圖例（選中高亮） ──
              ...shares.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final isSelected = i == _selectedIndex;
                final color = _chartColors[i % _chartColors.length];
                final val = _getPieValue(s);
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF0F4FA)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${s.name} (${s.symbol})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF1A1F2E)
                                  : const Color(0xFF5A6375),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${(val.abs() / totalVal * 100).toStringAsFixed(1)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? color
                                  : const Color(0xFF1A1F2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            '${AppFmt.num(val.abs())} 元',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ──子圖 chip 列 ──
  Widget _pieModeChips() {
    final modes = [
      (_PieMode.marketValue, '市值佔比'),
      (_PieMode.cost, '投入成本'),
      (_PieMode.unrealized, '未實現收益'),
    ];
    return Row(
      children: modes.map((item) {
        final (mode, label) = item;
        final isActive = _pieMode == mode;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() {
              _pieMode = mode;
              _selectedIndex = 0;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF4A6FA5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF4A6FA5)
                      : const Color(0xFFE4E7ED),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF5A6375),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// D  策略績效
// ════════════════════════════════════════════════════════════
class _StrategyTab extends StatelessWidget {
  final List<Trade> trades;
  final Map<String, double> tradePnLMap;
  const _StrategyTab({
    required this.trades, required this.tradePnLMap,
  });

  @override
  Widget build(BuildContext context) {
    final perfs = ChartService.buildStrategyPerf(trades, tradePnLMap);

    if (perfs.isEmpty) {
      return const Center(
        child: Text('尚無策略標籤資料',
          style: TextStyle(color: AppColors.textMuted)));
    }

    final maxAbs = perfs
        .map((p) => p.totalPnL.abs())
        .reduce(max);

    // ──整體勝率計算 ──
    final totalSell = perfs.fold(0, (s, p) => s + p.sellCount);
    final totalWin  = perfs.fold(0, (s, p) => s + p.winCount);
    final overallWR = totalSell == 0
        ? 0.0 : totalWin / totalSell;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ──StatsStrip ──
        StatsStrip(
          cells: [
            StatCell(
              label: '策略數量',
              value: '${perfs.length} 個',
            ),
            StatCell(
              label: '最佳策略',
              value: perfs.first.name,
              valueColor: AppColors.profit,
            ),
            StatCell(
              label: '整體勝率',
              value: '${(overallWR * 100).toStringAsFixed(0)}%',
              valueColor: overallWR >= 0.5
                  ? AppColors.profit
                  : AppColors.loss,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E7ED)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4, offset: const Offset(0, 1),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('策略標籤績效',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E),
                ),
              ),
              const SizedBox(height: 14),
              ...perfs.map((p) {
                final pnlColor = p.totalPnL >= 0
                    ? AppColors.profit
                    : AppColors.loss;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row( //上方策略名稱/收益/勝率
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1F2E),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                AppFmt.pnl(p.totalPnL),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700, color: pnlColor)),
                              const SizedBox(width: 10),
                              Text(
                                '勝率 ${(p.winRate*100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // ──雙向進度條 ──
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final totalWidth = constraints.maxWidth;
                          final halfWidth = totalWidth / 2;
                          final barW = maxAbs == 0
                              ? 0.0
                              : (p.totalPnL.abs() / maxAbs * halfWidth)
                                  .clamp(0.0, halfWidth);
                          final isPos = p.totalPnL >= 0;
                          return SizedBox(
                            height: 8,
                            child: Stack(
                              children: [
                                Container( //底色軌道
                                  width: totalWidth,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F2F5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Positioned( //中線
                                  left: halfWidth - 0.5,
                                  child: Container(
                                    width: 1, height: 8,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Positioned( //進度條
                                  left: isPos
                                      ? halfWidth
                                      : halfWidth - barW,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: isPos
                                          ? Radius.zero
                                          : const Radius.circular(4),
                                      bottomLeft: isPos
                                          ? Radius.zero
                                          : const Radius.circular(4),
                                      topRight: isPos
                                          ? const Radius.circular(4)
                                          : Radius.zero,
                                      bottomRight: isPos
                                          ? const Radius.circular(4)
                                          : Radius.zero,
                                    ),
                                    child: Container(
                                      width: barW, height: 8,
                                      color: pnlColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text( //下方交易筆數
                        '${p.tradeCount} 筆交易',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 共用 Widgets
// ════════════════════════════════════════════════════════════
class _RangeChips extends StatelessWidget { //時間範圍選擇器
  final List<String> options;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;
  const _RangeChips({
    required this.options, required this.labels,
    required this.selected, required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.asMap().entries.map((e) {
        final isActive = e.value == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(e.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF4A6FA5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                    ? const Color(0xFF4A6FA5)
                    : const Color(0xFFE4E7ED),
                ),
              ),
              child: Text(
                labels[e.key],
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF5A6375),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NavBtn extends StatelessWidget { //導航按鈕
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFEBF0F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFC5D4EC)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF4A6FA5),
        ),
      ),
    );
  }
}