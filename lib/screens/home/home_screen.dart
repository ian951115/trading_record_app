//主畫面UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/add_trade_result.dart';
import '../../repositories/cash_flow_repository.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/dividend_repository.dart';
import '../../services/calc/position_service.dart';
import '../../services/calc/portfolio_service.dart';
import '../../services/data/stock_price_service.dart';
import '../../widgets/common/hero_card.dart';
import '../../widgets/common/stats_strip.dart';
import '../../widgets/trade/trade_tile.dart';
import '../trade/trade_list_screen.dart';
import '../position/position_list_screen.dart';
import '../position/stock_performance_screen.dart';
import '../calendar/calendar_screen.dart';
import '../trade/add_trade_screen.dart';
import '../charts/charts_screen.dart';
import '../dividend/dividend_screen.dart';
import '../settings/settings_screen.dart';
import '../cash_flow/cash_flow_screen.dart';
import '../recurring/recurring_screen.dart';
import '../goals/goal_tracking_screen.dart';
import '../statistics/statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isObscured = false;
  final _pageCtrl = PageController();
  int _currentPage = 0;
  static const int _totalPages = 2;
  Map<String, double> _livePrices = {};
  bool _pricesFetched = false; //避免重複抓

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPrices());
  }

  Future<void> _fetchPrices() async {
    final tradeRepo = context.read<TradeRepository>();
    final dividendRepo = context.read<DividendRepository>();
    final result = buildPositions(
      tradeRepo.getAllTrades(),
      dividends: dividendRepo.getAllDividends(),
    );
    final symbols = result.positions
        .where((p) => p.quantity > 0)
        .map((p) => p.symbol)
        .toList();
    if (symbols.isEmpty) return; //資料還沒載入完成，先不標記fetched等下次build再試

    _pricesFetched = true;
    final prices = await StockPriceService.fetchPrices(symbols);
    if (mounted) {
      setState(() => _livePrices = prices);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final tradeRepo = context.watch<TradeRepository>();
    final cashRepo = context.watch<CashFlowRepository>();
    final dividendRepo = context.watch<DividendRepository>();

    final trades = tradeRepo.getAllTrades();
    final cashFlows = cashRepo.getAllFlows();
    final dividends = dividendRepo.getAllDividends();
    final result = buildPositions(trades, dividends: dividends);
    final positions = result.positions;
    for (final p in positions) {
      if (_livePrices.containsKey(p.symbol)) p.livePrice = _livePrices[p.symbol];
    }

    //首次build時Hive可能還沒載入完成，等真的有持倉資料後再補抓一次
    if (!_pricesFetched && positions.any((p) => p.quantity > 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPrices());
    }

    final hasCashData = cashFlows.isNotEmpty;

    final cash = PortfolioService.calculateCash(
      trades: trades,
      cashFlows: cashFlows,
    );
    final marketValue = PortfolioService.calculateMarketValue(positions);
    final totalAsset = PortfolioService.calculateTotalAsset(
      cash: cash,
      positions: positions,
    );
    final realizedPnL = PortfolioService.calculateTotalRealizedPnL(positions);
    final unrealizedPnL = PortfolioService.calculateTotalUnrealizedPnL(positions);

    final recentTrades = trades.take(5).toList();

    // ── 眼睛按鈕（傳入 HeroCard trailing）────
    final eyeButton = GestureDetector(
      onTap: () => setState(() => _isObscured = !_isObscured),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 16, color: Colors.white70,
        ),
      ),
    );

    // ── Hero 下方格子（有/無現金資料各不同）──
    final heroStats = hasCashData
        ? [
            HeroStat(label: '現金餘額', value: _isObscured ? '＊＊＊' : AppFmt.num(cash)),
            HeroStat(label: '持倉市值', value: _isObscured ? '＊＊＊' : AppFmt.num(marketValue)),
          ]
        : [
            HeroStat(label: '持倉市值', value: _isObscured ? '＊＊＊' : AppFmt.num(marketValue)),
            HeroStat(
              label: '持倉檔數',
              value: positions.where((p) => p.quantity > 0).length.toString(),
            ),
          ];

    Widget buildPage1() => GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.95,
      children: [
        _QuickItem(
          icon: Icons.receipt_long_outlined,
          label: '交易明細',
          color: AppColors.primaryLight,
          iconColor: AppColors.primary,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TradeListScreen())),
        ),
        _QuickItem(
          icon: Icons.inventory_2_outlined,
          label: '庫存明細',
          color: AppColors.lossBg,
          iconColor: AppColors.loss,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PositionListScreen())),
        ),
        _QuickItem(
          icon: Icons.calendar_month_outlined,
          label: '收益日曆',
          color: AppColors.profitBg,
          iconColor: AppColors.profit,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => CalendarScreen())),
        ),
        _QuickItem(
          icon: Icons.flag_circle_outlined,
          label: '目標追蹤',
          color: AppColors.primaryLight,
          iconColor: AppColors.primary,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => GoalTrackingScreen())),
        ),
        _QuickItem(
          icon: Icons.show_chart,
          label: '各式圖表',
          color: AppColors.primaryLight,
          iconColor: AppColors.primary,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ChartsScreen())),
        ),
        _QuickItem(
          icon: Icons.savings_outlined,
          label: '股利紀錄',
          color: AppColors.lossBg,
          iconColor: AppColors.loss,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DividendScreen())),
        ),
        _QuickItem(
          icon: Icons.account_balance_wallet_outlined,
          label: '資金管理',
          color: AppColors.profitBg,
          iconColor: AppColors.profit,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CashFlowScreen())),
        ),
        _QuickItem(
          icon: Icons.bar_chart,
          label: '個股績效',
          color: AppColors.primaryLight,
          iconColor: AppColors.primary,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StockPerformanceScreen())),
        ),
      ],
    );

    Widget buildPage2() => GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.95,
      children: [
        _QuickItem(
          icon: Icons.repeat_outlined,
          label: '定期定額',
          color: AppColors.primaryLight,
          iconColor: AppColors.primary,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RecurringScreen())),
        ),
        _QuickItem(
          icon: Icons.emoji_events_outlined,
          label: '歷史之最',
          color: AppColors.primaryLight,
          iconColor: AppColors.primary,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen())),
        )
      ],
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('交易紀錄'),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize( //標題下方分隔線
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.border,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                
                // ── Hero 卡片 ──────────────────
                HeroCard(
                  title: '總資產估值',
                  trailing: eyeButton,
                  mainValue: Text(
                    _isObscured ? '＊＊＊＊＊' : AppFmt.num(totalAsset),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  stats: heroStats,
                ),

                const SizedBox(height: 12),

                // ── 損益統計列 ─────────────────
                StatsStrip(
                  cells: [
                    StatCell(
                      label: '已實現損益',
                      value: _isObscured
                          ? '＊＊＊'
                          : AppFmt.pnl(realizedPnL),
                      valueColor: AppColors.pnl(realizedPnL),
                    ),
                    StatCell(
                      label: '未實現損益',
                      value: _isObscured
                          ? '＊＊＊'
                          : AppFmt.pnl(unrealizedPnL),
                      valueColor: AppColors.pnl(unrealizedPnL),
                    ),
                    StatCell(
                      label: '持倉檔數',
                      value: positions
                          .where((p) => p.quantity > 0)
                          .length
                          .toString(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── 快捷功能 2×4 ───────────────
                const _SectionHeader(title: '快捷功能'),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemW = (constraints.maxWidth - 8 *3) / 4;
                    final itemH = itemW / 0.95;
                    final gridH = itemH * 2 + 8;
                    return SizedBox(
                      height: gridH,
                      child: PageView(
                        controller: _pageCtrl,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        children: [buildPage1(), buildPage2()],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row( //圓點指示器
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalPages, (i) =>
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 16 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── 最近交易 ───────────────────
                _SectionHeader(
                  title: '最近交易',
                  action: '查看全部',
                  onAction: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TradeListScreen())),
                ),
                const SizedBox(height: 10),

                if (recentTrades.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.border,
                          ),
                          SizedBox(height: 12),
                          Text(
                            '尚無交易紀錄',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentTrades.map((trade) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TradeTile(trade: trade),
                  )),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<AddTradeResult>(
            context,
            MaterialPageRoute(builder: (_) => const AddTradeScreen()),
          );
          if (result != null && mounted) {
            context.read<TradeRepository>().addTrade(result.trade);
            if (result.autoDeposit != null) {
              context.read<CashFlowRepository>().addFlow(result.autoDeposit!);
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── 區塊標題 ───────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ── 快捷功能格子 ───────────────────────────────
class _QuickItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecond,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}