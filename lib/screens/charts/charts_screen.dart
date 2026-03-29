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
            unselectedLabelColor: const Color(0xFF9AA3B2), //其他分頁顏色
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
        ],
      ),
    );
  }
}

//總資產折線圖
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
  int? _touchedSpotIndex; //觸碰點索引（用於tooltip）

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

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final allData = ChartService.buildAssetHistory(
      trades: widget.trades, cashFlows: widget.cashFlows);
    final data = _filterByRange(allData);

    if (data.isEmpty) {
      return const Center(
        child: Text(
          '尚無資料',
          style: TextStyle(color: Color(0xFF9AA3B2)),
        ),
      );
    }

    final maxAsset = data.map((d) => d.totalAsset).reduce((a, b) => a > b ? a : b); //找max
    final minAsset = data.map((d) => d.totalAsset).reduce((a, b) => a < b ? a : b); //找min
    final current = data.last.totalAsset;
    final first = data.first.totalAsset;
    final change = current - first;
    final changePct = first == 0 ? 0.0 : change / first * 100; //範圍內資產變化率
    final changeColor = change >= 0
        ? const Color(0xFFE8504A)
        : const Color(0xFF3D9E6B);

    //建立總資產曲線資料點
    final spots = data.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.totalAsset),
    ).toList();

    //X軸日期標籤只顯示頭、中、尾
    final labelIndices = {0, data.length ~/ 2, data.length - 1};
    String xLabel(int i) { //指定的日期顯示
      final d = data[i].date;
      return '${d.month}/${d.day}';
    }

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
              const SizedBox(height: 14),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minY: minAsset * 0.95,
                    maxY: maxAsset * 1.05, //y軸對應的最大值
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
                          getTitlesWidget: (v, _) => Text(
                            '${(v/10000).toStringAsFixed(0)}萬',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF9AA3B2),
                            ),
                          ),
                        ),
                      ),
                      rightTitles: AxisTitles( //右邊不顯示
                        sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles( //上方不顯示
                        sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles( //下方顯示日期
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (!labelIndices.contains(i) || i >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              xLabel(i),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF9AA3B2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // ── 自訂 Tooltip ──
                    lineTouchData: LineTouchData( //日期對應資料方框
                      touchCallback: (event, response) { //對選取的反應
                        setState(() {
                          _touchedSpotIndex = response
                              ?.lineBarSpots?.first.x.toInt();
                        });
                      },
                      touchTooltipData: LineTouchTooltipData( //內容
                        tooltipBgColor: const Color(0xFF1A1F2E).withValues(alpha: 0.85),
                        getTooltipItems: (spots) {
                          return spots.map((s) {
                            final i = s.spotIndex;
                            final d = i < data.length
                                ? data[i].date : null;
                            final dateStr = d != null
                                ? '${d.month}/${d.day}' : '';
                            return LineTooltipItem(
                              '$dateStr\n${formatter.format(s.y.toInt())}',
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
                    lineBarsData: [ //曲線及座標點
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF4A6FA5),
                        barWidth: 2,
                        dotData: FlDotData( //座標點
                          show: true,
                          checkToShowDot: (spot, barData) =>
                              spot.x.toInt() == _touchedSpotIndex,
                          getDotPainter: (_, __, ___, ____) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: const Color(0xFF4A6FA5),
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                        ),
                        belowBarData: BarAreaData( //線下
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
        _HighlightCard(data: data, formatter: formatter), //亮點卡片
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

    final total = monthlyPnL.values.fold(0.0, (s, v) => s + v);

    //最佳月份只考慮有賣出的月份（pnl != 0）
    final nonZeroEntries = monthlyPnL.entries.where((e) => e.value != 0).toList();
    final bestMonth = nonZeroEntries.isEmpty
        ? null
        : nonZeroEntries.reduce((a, b) => a.value > b.value ? a : b).key;

    //Y軸分開取最大正值和最小負值，不強制對稱
    final allValues = List.generate(12, (i) => monthlyPnL[i + 1] ?? 0.0);
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    final minVal = allValues.reduce((a, b) => a < b ? a : b);

    //沒有任何資料時用預設尺度
    final hasData = nonZeroEntries.isNotEmpty;
    final double chartMaxY = hasData ? maxVal * 1.3 : 100000;
    final double chartMinY = hasData ? (minVal < 0 ? minVal * 1.3 : -10000) : -100000;

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
              value: bestMonth == null ? '—' : '$bestMonth 月',
              valueColor: bestMonth == null
                  ? null
                  : const Color(0xFFE8504A),
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
              Text(
                '每月損益 · $year 年',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E),
                ),
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
                            ? const Color(0xFF9AA3B2)
                            : const Color(0xFFE4E7ED),
                        strokeWidth: v == 0 ? 1.5 : 1, //零線加粗
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    // ── 自訂 Tooltip ──
                    barTouchData: BarTouchData( //日期對應資料方框
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: const Color(0xFF1A1F2E).withValues(alpha: 0.85),
                        getTooltipItem: (group, _, rod, __) { //內容
                          final pnl = rod.toY;
                          return BarTooltipItem(
                            '${group.x}月\n'
                            '${pnl >= 0 ? '+' : ''}'
                            '${formatter.format(pnl.toInt())}',
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
                              color: Color(0xFF9AA3B2),
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
                            final abs = v.abs();
                            final label = abs >= 10000
                                ? '${(v / 10000).toStringAsFixed(0)}萬'
                                : v.toStringAsFixed(0);
                            return Text(
                              label,
                              style: const TextStyle(
                                fontSize: 8,
                                color: Color(0xFF9AA3B2),
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

//持股佔比圓餅圖
class _PieTab extends StatelessWidget {
  final List<Position> openPositions;
  const _PieTab({required this.openPositions});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final shares = ChartService.buildHoldingShares(openPositions);

    if (shares.isEmpty) { //比例永遠顯示，不需要touch state
      return const Center(child: Text('目前沒有持倉',
        style: TextStyle(color: Color(0xFF9AA3B2))));
    }

     //決定 比例/顏色/數值
    final sections = shares.asMap().entries.map((e) {
      final i = e.key;
      final s = e.value;
      return PieChartSectionData(
        value: s.marketValue,
        color: _chartColors[i % _chartColors.length],
        radius: 70,
        showTitle: true,
        title: '${s.percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
        ),
        titlePositionPercentageOffset: 0.65, //數值離圓心距離
      );
    }).toList();

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
              const Text('當前持股市值佔比',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: sections, //區塊數據
                    sectionsSpace: 2, //區塊間格
                    centerSpaceRadius: 36, //中心圓半徑
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...shares.asMap().entries.map((e) { //圖例
                final i = e.key;
                final s = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: _chartColors[i % _chartColors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${s.name} (${s.symbol})',
                          style: const TextStyle(
                            fontSize: 12, color: Color(0xFF5A6375)))),
                        Text(
                          '${s.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F2E))),
                        const SizedBox(width: 10),
                        Text(
                          '${formatter.format(s.marketValue.toInt())} 元',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9AA3B2))),
                    ],
                  ),
                );
              },
            ),
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
                    ? const Color(0xFFE8504A)
                    : const Color(0xFF3D9E6B);
                final barWidth = maxAbs == 0 ? 0.0 : p.totalPnL.abs() / maxAbs; //百分比條長度
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
                                (p.totalPnL >= 0 ? '+' : '') +
                                    formatter.format(p.totalPnL.toInt()),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700, color: pnlColor)),
                              const SizedBox(width: 10),
                              Text(
                                '勝率 ${(p.winRate*100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9AA3B2))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect( //中間百分比條
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: barWidth,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF0F2F5),
                          valueColor: AlwaysStoppedAnimation(pnlColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text( //下方交易筆數
                        '${p.tradeCount} 筆交易',
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

class _HighlightCard extends StatelessWidget { //亮點卡片
  final List<AssetDataPoint> data;
  final NumberFormat formatter;
  const _HighlightCard({
    required this.data, required this.formatter,
  });
  @override
  Widget build(BuildContext context) {
    final maxPoint = data.reduce((a,b) => a.totalAsset > b.totalAsset ? a : b);
    final minPoint = data.reduce((a,b) => a.totalAsset < b.totalAsset ? a : b);
    double maxDailyChange = 0; //最大單日變化
    DateTime maxDailyDate = data.first.date;
    for (int i = 1; i < data.length; i++) {
      final change = data[i].totalAsset - data[i-1].totalAsset;
      if (change > maxDailyChange) {
        maxDailyChange = change;
        maxDailyDate = data[i].date;
      }
    }
    String fmt(DateTime d) => '${d.month}/${d.day}';

    return Container(
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
          const Text('📌 期間亮點',
            style: TextStyle(
              fontSize: 12, color: Color(0xFF9AA3B2))),
          const SizedBox(height: 10),
          Row(
            children: [
              _HighlightItem(
                label: '最高資產',
                value: formatter.format(maxPoint.totalAsset.toInt()),
                sub: fmt(maxPoint.date),
                color: const Color(0xFFE8504A),
                bgColor: const Color(0xFFFDF0EF),
              ),
              const SizedBox(width: 8),
              _HighlightItem(
                label: '最低資產',
                value: formatter.format(minPoint.totalAsset.toInt()),
                sub: fmt(minPoint.date),
                color: const Color(0xFF3D9E6B),
                bgColor: const Color(0xFFEEF7F2),
              ),
              const SizedBox(width: 8),
              _HighlightItem(
                label: '最大單日漲幅',
                value: '+${formatter.format(maxDailyChange.toInt())}',
                sub: fmt(maxDailyDate),
                color: const Color(0xFF4A6FA5),
                bgColor: const Color(0xFFEBF0F8),
              ),
            ],
          ),
        ],
      ),
    );
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
              style: const TextStyle(fontSize: 9, color: Color(0xFF9AA3B2)),
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
              style: const TextStyle(fontSize: 9, color: Color(0xFF9AA3B2)),
            ),
          ],
        ),
      ),
    );
  }
}
