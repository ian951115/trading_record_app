//庫存明細ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/position.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/dividend_repository.dart';
import '../../services/calc/position_service.dart';
import '../../services/data/stock_price_service.dart';
import '../../widgets/common/hero_card.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPrices());
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

    setState(() =>  _isLoading = true);
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

    final result = buildPositions(trades, dividends: dividends);
    final allPositions = result.positions;
    for (final p in allPositions) {
      if (_livePrices.containsKey(p.symbol)) p.livePrice = _livePrices[p.symbol];
    }

    final openPositions = allPositions
        .where((p) => p.quantity > 0).toList(); //庫存(>0)
    final totalMV = openPositions.fold(0.0, (s, p) => s + p.marketValue);
    final totalCost = openPositions.fold(0.0, (s, p) => s + p.totalCost);
    final totalUnrealized = totalMV - totalCost;
    final totalReturn = totalCost == 0
        ? 0.0 : (totalUnrealized / totalCost) * 100;

    //深藍背景上的損益對比色
    final pnlOnDark = totalUnrealized >= 0
        ? const Color(0xFFFFD6D4)
        : const Color(0xFFB8F0D0);

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
                    color: AppColors.primary,
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
                  color: AppColors.lossBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '即時更新',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.loss,
                  ),
                ),
              ),
            ),
          //刷新按鈕
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _fetchPrices,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedRotation(
                  turns: _rotationTurns,
                  duration: const Duration(milliseconds: 500),
                  child: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: AppColors.primary,
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
        pnlOnDark: pnlOnDark,
      ),
    );
  }
}

class _HoldingTab extends StatelessWidget { //持有頁面
  final List<Position> openPositions;
  final double totalMV, totalCost, totalUnrealized, totalReturn;
  final Color pnlOnDark;

  const _HoldingTab({
    required this.openPositions,
    required this.totalMV,
    required this.totalCost,
    required this.totalUnrealized,
    required this.totalReturn,
    required this.pnlOnDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding( //Hero總覽卡片
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: HeroCard(
            title: '持倉總市值',
            mainValue: Text(
              AppFmt.num(totalMV),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            stats: [
              HeroStat(label: '總成本', value: AppFmt.num(totalCost)),
              HeroStat(
                label: '未實現損益',
                value: AppFmt.pnl(totalUnrealized),
                valueColor: pnlOnDark,
              ),
              HeroStat(
                label: '報酬率',
                value: '${totalReturn >= 0 ? '+' : ''}'
                      '${totalReturn.toStringAsFixed(2)}%',
                valueColor: pnlOnDark,
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
                      color: AppColors.border,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '目前沒有持倉',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                itemCount: openPositions.length,
                separatorBuilder: (_,_) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                  PositionTile(position: openPositions[index]),
              ),
        ),
      ],
    );
  }
}