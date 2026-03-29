//庫存明細ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/dividend_repository.dart';
import '../../services/position_service.dart';
import '../../services/stock_price_service.dart';
import '../../models/position.dart';
import '../../widgets/position/position_tile.dart';

class PositionListScreen extends StatefulWidget {
  const PositionListScreen({super.key});

  @override
  State<PositionListScreen> createState() => _PositionListScreenState();
}

class _PositionListScreenState extends State<PositionListScreen> {
  Map<String, double> _livePrices = {};
  bool _isLoading = false;
  double _rotationTurns = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPrices();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchPrices() async {
    final repo = context.read<TradeRepository>();
    final result = buildPositions(repo.getAllTrades());
    final symbols = result.positions
        .where((p) => p.quantity > 0)
        .map((p) => p.symbol)
        .toList();
    if (symbols.isEmpty) return;

    setState(() { _isLoading = true; });
    final prices = await StockPriceService.fetchPrices(symbols);
    if (mounted) {
      setState(() {
        _livePrices = prices;
        _isLoading = false;
        _rotationTurns += 1;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final repository = context.watch<TradeRepository>();
    final trades = repository.getAllTrades();
    final divRepo = context.watch<DividendRepository>();
    final dividends = divRepo.getAllDividends();

    final result = buildPositions(
      trades,
      dividends: dividends,
    );

    final formatter = NumberFormat('#,###');

    final allPositions = result.positions;
    for (final p in allPositions) {
      if (_livePrices.containsKey(p.symbol)) {
        p.livePrice = _livePrices[p.symbol];
      }
    }

    final openPositions = allPositions
        .where((p) => p.quantity > 0).toList(); //庫存(>0)

    final totalMV = openPositions.fold(
        0.0, (s, p) => s + p.marketValue);
    final totalCost = openPositions.fold(
        0.0, (s, p) => s + p.totalCost);
    final totalUnrealized = totalMV - totalCost;
    final totalReturn = totalCost == 0
        ? 0.0 : (totalUnrealized / totalCost) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('庫存明細'),
        actions: [
          //更新狀態標籤
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4A6FA5),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF7F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '即時更新',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D9E6B),
                  ),
                ),
              ),
            ),
          //刷新按鈕
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _fetchPrices,
              child: AnimatedRotation(
                turns: _rotationTurns,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF0F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Color(0xFF4A6FA5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _HoldingTab(
        openPositions: openPositions,
        totalMV: totalMV,
        totalCost: totalCost,
        totalUnrealized: totalUnrealized,
        totalReturn: totalReturn,
        formatter: formatter,
      ),
    );
  }
}

class _HoldingTab extends StatelessWidget { //持有頁面
  final List<Position> openPositions;
  final double totalMV;
  final double totalCost;
  final double totalUnrealized;
  final double totalReturn;
  final NumberFormat formatter;

  const _HoldingTab({
    required this.openPositions,
    required this.totalMV,
    required this.totalCost,
    required this.totalUnrealized,
    required this.totalReturn,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container( //Hero總覽卡片
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D4A7A),
                Color(0xFF4A6FA5),
                Color(0xFF5E85BF),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '持倉總市值',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white60,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatter.format(totalMV.toInt()),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _HeroStat(
                    label: '總成本',
                    value: formatter.format(totalCost.toInt()),
                  ),
                  Container(
                    width: 1, height: 28,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  _HeroStat(
                    label: '未實現損益',
                    value: (totalUnrealized >= 0 ? '+' : '') +
                        formatter.format(totalUnrealized.toInt()),
                    valueColor: totalUnrealized >= 0
                        ? const Color(0xFFFFD6D4)
                        : const Color(0xFFB8F0D0),
                  ),
                  Container(
                    width: 1, height: 28,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  _HeroStat(
                    label: '報酬率',
                    value: '${totalReturn >= 0 ? '+' : ''}'
                        '${totalReturn.toStringAsFixed(2)}%',
                    valueColor: totalUnrealized >= 0
                        ? const Color(0xFFFFD6D4)
                        : const Color(0xFFB8F0D0),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Expanded( //持股列表
          child: openPositions.isEmpty
              ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Color(0xFFE4E7ED),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '目前沒有持倉',
                      style: TextStyle(color: Color(0xFF9AA3B2), fontSize: 14),
                    ),
                  ],
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                itemCount: openPositions.length,
                separatorBuilder: (_,__) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return PositionTile(
                    position: openPositions[index],
                  );
                },
              ),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget { //卡片小資訊
  final String label;
  final String value;
  final Color valueColor;

  const _HeroStat({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}