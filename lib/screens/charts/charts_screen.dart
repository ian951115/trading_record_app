//各式圖表
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/trade.dart';
import '../../models/position.dart';
import '../../models/cash_flow.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/cash_flow_repository.dart';
import '../../services/chart_service.dart';
import '../../services/position_service.dart';
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
  String _assetRange = 'all'; // 1m / 3m / 1y / all
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
    final openPositions = posResult.positions
        .where((p) => p.quantity > 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('各式圖表')),
      body: Column(children: [
        // Tab 列
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF4A6FA5),
          unselectedLabelColor: const Color(0xFF9AA3B2),
          indicatorColor: const Color(0xFF4A6FA5),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '總資產'),
            Tab(text: '每月損益'),
            Tab(text: '持股佔比'),
            Tab(text: '策略績效'),
          ],
        ),
        const Divider(height: 1),
        // 內容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AssetTab(
                trades: trades,
                cashFlows: cashFlows,
                range: _assetRange,
                onRangeChanged: (r) =>
                    setState(() => _assetRange = r),
              ),
              _MonthlyTab(
                trades: trades,
                year: _monthlyYear,
                onYearChanged: (y) =>
                    setState(() => _monthlyYear = y),
              ),
              _PieTab(openPositions: openPositions),
              _StrategyTab(
                trades: trades,
                tradePnLMap: posResult.tradePnLMap,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

//總資產折線圖
class _AssetTab extends StatelessWidget {
  final List<Trade> trades;
  final List<CashFlow> cashFlows;
  final String range;
  final ValueChanged<String> onRangeChanged;
  const _AssetTab({
    required this.trades, required this.cashFlows,
    required this.range, required this.onRangeChanged,
  });

  List<AssetDataPoint> _filterByRange(
      List<AssetDataPoint> data) {
    if (range == 'all') return data;
    final now = DateTime.now();
    final cutoff = switch (range) {
      '1m' => DateTime(now.year, now.month - 1, now.day),
      '3m' => DateTime(now.year, now.month - 3, now.day),
      '1y' => DateTime(now.year - 1, now.month, now.day),
      _ => DateTime(1961),
    };
    return data.where((d) =>
      !d.date.isBefore(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final allData = ChartService.buildAssetHistory(
      trades: trades, cashFlows: cashFlows);
    final data = _filterByRange(allData);

    if (data.isEmpty) {
      return const Center(child: Text('尚無資料',
        style: TextStyle(color: Color(0xFF9AA3B2))));
    }

    final maxAsset = data
        .map((d) => d.totalAsset).reduce((a,b) => a>b?a:b);
    final minAsset = data
        .map((d) => d.totalAsset).reduce((a,b) => a<b?a:b);
    final current = data.last.totalAsset;
    final first = data.first.totalAsset;
    final change = current - first;
    final changePct = first == 0 ? 0.0 : change / first * 100;
    final changeColor = change >= 0
        ? const Color(0xFFE8504A)
        : const Color(0xFF3D9E6B);

    // 建立 fl_chart 資料點
    final spots = data.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.totalAsset),
    ).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // 時間範圍選擇
        _RangeChips(
          options: const ['1m','3m','1y','all'],
          labels: const ['1月','3月','1年','全部'],
          selected: range,
          onChanged: onRangeChanged,
        ),
        const SizedBox(height: 10),
        // 統計列
        StatsStrip(cells: [
          StatCell(
            label: '目前總資產',
            value: formatter.format(current.toInt()),
            valueColor: const Color(0xFF4A6FA5),
          ),
          StatCell(
            label: '期間變化',
            value: (change >= 0 ? '+' : '') +
                formatter.format(change.toInt()),
            valueColor: changeColor,
          ),
          StatCell(
            label: '變化率',
            value: '${changePct >= 0 ? '+' : ''}'
                '${changePct.toStringAsFixed(1)}%',
            valueColor: changeColor,
          ),
        ]),
        const SizedBox(height: 10),
        // 折線圖卡片
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
              const Text('總資產變化曲線',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E))),
              const SizedBox(height: 14),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: minAsset * 0.95,
                    maxY: maxAsset * 1.05,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: const Color(0xFFE4E7ED),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          getTitlesWidget: (v, _) => Text(
                            '${(v/10000).toStringAsFixed(0)}萬',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF9AA3B2))),
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF4A6FA5),
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF4A6FA5)
                                .withValues(alpha: 0.18),
                              const Color(0xFF4A6FA5)
                                .withValues(alpha: 0.01),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 亮點卡片
        _HighlightCard(data: data, formatter: formatter),
      ],
    );
  }
}

//每月損益長條圖
class _MonthlyTab extends StatelessWidget {
  final List<Trade> trades;
  final int year;
  final ValueChanged<int> onYearChanged;
  const _MonthlyTab({
    required this.trades, required this.year,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final monthlyPnL = ChartService.buildMonthlyPnL(
      trades: trades, year: year);

    final total = monthlyPnL.values
        .fold(0.0, (s, v) => s + v);
    final bestMonth = monthlyPnL.isEmpty ? 0
        : monthlyPnL.entries
            .reduce((a,b) => a.value > b.value ? a : b).key;

    // 最大絕對值（用於長條圖比例計算）
    final maxAbs = monthlyPnL.isEmpty ? 1.0
        : monthlyPnL.values
            .map((v) => v.abs())
            .reduce((a,b) => a > b ? a : b);

    // 建立 BarChart 資料
    final groups = List.generate(12, (i) {
      final month = i + 1;
      final pnl = monthlyPnL[month] ?? 0.0;
      return BarChartGroupData(
        x: month,
        barRods: [
          BarChartRodData(
            toY: pnl,
            color: pnl >= 0
                ? const Color(0xFFE8504A)
                : const Color(0xFF3D9E6B),
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // 年份切換
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavBtn(
              icon: Icons.chevron_left,
              onTap: () => onYearChanged(year - 1),
            ),
            const SizedBox(width: 16),
            Text('$year 年',
              style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F2E))),
            const SizedBox(width: 16),
            _NavBtn(
              icon: Icons.chevron_right,
              onTap: () => onYearChanged(year + 1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatsStrip(cells: [
          StatCell(
            label: '年度損益',
            value: (total >= 0 ? '+' : '') +
                formatter.format(total.toInt()),
            valueColor: total >= 0
                ? const Color(0xFFE8504A)
                : const Color(0xFF3D9E6B),
          ),
          StatCell(
            label: '獲利月份',
            value: '${monthlyPnL.values.where((v) => v > 0).length} 月',
          ),
          StatCell(
            label: '最佳月份',
            value: bestMonth == 0 ? '—' : '$bestMonth 月',
            valueColor: const Color(0xFFE8504A),
          ),
        ]),
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
              Text('每月損益 · $year 年',
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E))),
              const SizedBox(height: 14),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxAbs * 1.2,
                    minY: -maxAbs * 1.2,
                    barGroups: groups,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: const Color(0xFFE4E7ED),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}月',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Color(0xFF9AA3B2))),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (v, _) => Text(
                            v == 0 ? '0'
                              : '${(v/10000).toStringAsFixed(0)}萬',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Color(0xFF9AA3B2))),
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

//持股佔比圓餅圖
class _PieTab extends StatefulWidget {
  final List<Position> openPositions;
  const _PieTab({required this.openPositions});
  @override
  State<_PieTab> createState() => _PieTabState();
}

class _PieTabState extends State<_PieTab> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final shares = ChartService.buildHoldingShares(
      widget.openPositions);

    if (shares.isEmpty) {
      return const Center(child: Text('目前沒有持倉',
        style: TextStyle(color: Color(0xFF9AA3B2))));
    }

    final sections = shares.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      final isTouched = _touchedIndex == i;
      return PieChartSectionData(
        value: s.marketValue,
        color: _chartColors[i % _chartColors.length],
        radius: isTouched ? 80 : 65,
        showTitle: isTouched,
        title: '${s.percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: Colors.white),
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E7ED)),
          ),
          child: Column(children: [
            const Text('當前持股市值佔比',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F2E))),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex = response
                          ?.touchedSection
                          ?.touchedSectionIndex;
                    });
                  },
                ),
              )),
            ),
            const SizedBox(height: 14),
            // 圖例
            ...shares.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _chartColors[i % _chartColors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '${s.name} (${s.symbol})',
                    style: const TextStyle(
                      fontSize: 12, color: Color(0xFF5A6375)))),
                  Text(
                    '${s.percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F2E))),
                  const SizedBox(width: 8),
                  Text(
                    formatter.format(s.marketValue.toInt()),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9AA3B2))),
                ]),
              );
            }),
          ]),
        ),
      ],
    );
  }
}

//策略績效
class _StrategyTab extends StatelessWidget {
  final List<Trade> trades;
  final Map<String, double> tradePnLMap;
  const _StrategyTab({
    required this.trades, required this.tradePnLMap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final perfs = ChartService.buildStrategyPerf(
      trades, tradePnLMap);

    if (perfs.isEmpty) {
      return const Center(
        child: Text('尚無策略標籤資料',
          style: TextStyle(color: Color(0xFF9AA3B2))));
    }

    final maxAbs = perfs
        .map((p) => p.totalPnL.abs())
        .reduce((a,b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E7ED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('策略標籤績效',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E))),
              const SizedBox(height: 14),
              ...perfs.map((p) {
                final pnlColor = p.totalPnL >= 0
                    ? const Color(0xFFE8504A)
                    : const Color(0xFF3D9E6B);
                final barWidth = maxAbs == 0 ? 0.0
                    : p.totalPnL.abs() / maxAbs;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1F2E))),
                          Row(children: [
                            Text(
                              (p.totalPnL >= 0 ? '+' : '') +
                                  formatter.format(
                                    p.totalPnL.toInt()),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: pnlColor)),
                            const SizedBox(width: 8),
                            Text(
                              '勝率 ${(p.winRate*100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9AA3B2))),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: barWidth,
                          minHeight: 8,
                          backgroundColor:
                            const Color(0xFFF0F2F5),
                          valueColor:
                            AlwaysStoppedAnimation(pnlColor),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('${p.tradeCount} 筆交易',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9AA3B2))),
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

//-----
//共用小元件
//-----

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
    return Row(children: options.asMap().entries.map((e) {
      final isActive = e.value == selected;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onChanged(e.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4A6FA5) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive
                  ? const Color(0xFF4A6FA5)
                  : const Color(0xFFE4E7ED)),
            ),
            child: Text(labels[e.key],
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : const Color(0xFF5A6375))),
          ),
        ),
      );
    }).toList());
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
        child: Icon(icon, size: 18,
          color: const Color(0xFF4A6FA5)),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget { //亮點卡片
  final List<AssetDataPoint> data;
  final NumberFormat formatter;
  const _HighlightCard({
    required this.data, required this.formatter,
  });
  @override
  Widget build(BuildContext context) {
    final maxPoint = data.reduce(
      (a,b) => a.totalAsset > b.totalAsset ? a : b);
    final minPoint = data.reduce(
      (a,b) => a.totalAsset < b.totalAsset ? a : b);
    // 最大單日變化
    double maxDailyChange = 0;
    DateTime maxDailyDate = data.first.date;
    for (int i = 1; i < data.length; i++) {
      final change = data[i].totalAsset - data[i-1].totalAsset;
      if (change > maxDailyChange) {
        maxDailyChange = change;
        maxDailyDate = data[i].date;
      }
    }
    String fmt(DateTime d) =>
      '${d.month}/${d.day}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📌 期間亮點',
            style: TextStyle(
              fontSize: 12, color: Color(0xFF9AA3B2))),
          const SizedBox(height: 10),
          Row(children: [
            _HighlightItem(
              label: '最高資產',
              value: formatter.format(
                maxPoint.totalAsset.toInt()),
              sub: fmt(maxPoint.date),
              color: const Color(0xFFE8504A),
              bgColor: const Color(0xFFFDF0EF),
            ),
            const SizedBox(width: 8),
            _HighlightItem(
              label: '最低資產',
              value: formatter.format(
                minPoint.totalAsset.toInt()),
              sub: fmt(minPoint.date),
              color: const Color(0xFF3D9E6B),
              bgColor: const Color(0xFFEEF7F2),
            ),
            const SizedBox(width: 8),
            _HighlightItem(
              label: '最大單日漲幅',
              value: '+${formatter.format(
                maxDailyChange.toInt())}',
              sub: fmt(maxDailyDate),
              color: const Color(0xFF4A6FA5),
              bgColor: const Color(0xFFEBF0F8),
            ),
          ]),
        ],
      ),
    );
  }
}

class _HighlightItem extends StatelessWidget {
  final String label, value, sub;
  final Color color, bgColor;
  const _HighlightItem({
    required this.label, required this.value,
    required this.sub, required this.color,
    required this.bgColor,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(label, style: const TextStyle(
          fontSize: 9, color: Color(0xFF9AA3B2)),
          textAlign: TextAlign.center),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: color),
          textAlign: TextAlign.center),
        Text(sub, style: const TextStyle(
          fontSize: 9, color: Color(0xFF9AA3B2))),
      ]),
    ));
  }
}
