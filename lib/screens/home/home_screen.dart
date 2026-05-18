//主畫面UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/add_trade_result.dart';
import '../../repositories/cash_flow_repository.dart';
import '../../repositories/trade_repository.dart';
import '../../services/calc/position_service.dart';
import '../../services/calc/portfolio_service.dart';
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

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final tradeRepo = context.watch<TradeRepository>();
    final cashRepo = context.watch<CashFlowRepository>();

    final trades = tradeRepo.getAllTrades();
    final cashFlows = cashRepo.getAllFlows();
    final result = buildPositions(trades);
    final positions = result.positions;
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
          color: const Color(0xFFEBF0F8),
          iconColor: const Color(0xFF4A6FA5),
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TradeListScreen())),
        ),
        _QuickItem(
          icon: Icons.inventory_2_outlined,
          label: '庫存明細',
          color: const Color(0xFFEEF7F2),
          iconColor: AppColors.loss,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PositionListScreen())),
        ),
        _QuickItem(
          icon: Icons.calendar_month_outlined,
          label: '收益日曆',
          color: const Color(0xFFFDF0EF),
          iconColor: AppColors.profit,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => CalendarScreen())),
        ),
        _QuickItem(
          icon: Icons.flag_circle_outlined,
          label: '目標追蹤',
          color: const Color(0xFFEBF0F8),
          iconColor: const Color(0xFF4A6FA5),
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => GoalTrackingScreen())),
        ),
        _QuickItem(
          icon: Icons.show_chart,
          label: '各式圖表',
          color: const Color(0xFFEBF0F8),
          iconColor: const Color(0xFF4A6FA5),
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ChartsScreen())),
        ),
        _QuickItem(
          icon: Icons.savings_outlined,
          label: '股利紀錄',
          color: const Color(0xFFEEF7F2),
          iconColor: AppColors.loss,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DividendScreen())),
        ),
        _QuickItem(
          icon: Icons.account_balance_wallet_outlined,
          label: '資金管理',
          color: const Color(0xFFFDF0EF),
          iconColor: AppColors.profit,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CashFlowScreen())),
        ),
        _QuickItem(
          icon: Icons.bar_chart,
          label: '個股績效',
          color: const Color(0xFFEBF0F8),
          iconColor: const Color(0xFF4A6FA5),
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
          color: const Color(0xFFEBF0F8),
          iconColor: const Color(0xFF4A6FA5),
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
                  color: Color(0xFF4A6FA5),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize( //???
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: const Color(0xFFE4E7ED),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                
                // ── Hero 卡片 ──────────────────
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3D5A8A),
                            Color(0xFF4A6FA5),
                            Color(0xFF5E85BE),
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
                          //第一行：標籤 + 佔位（讓眼睛按鈕的空間）
                          Row(
                            children: [
                              const Text(
                                '總資產估值',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 36), //眼睛按鈕的佔位
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isObscured
                                ? '＊＊＊＊＊'
                                : AppFmt.num(totalAsset),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 14),
                          //只有有入金資料才顯示現金和市值
                          if (hasCashData)
                            Row(
                              children: [
                                _HeroStat(
                                  label: '現金餘額',
                                  value: _isObscured
                                      ? '＊＊＊'
                                      : AppFmt.num(cash),
                                ),
                                const _HeroDivider(),
                                _HeroStat(
                                  label: '持倉市值',
                                  value: _isObscured
                                      ? '＊＊＊'
                                      : AppFmt.num(marketValue),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                _HeroStat(
                                  label: '持倉市值',
                                  value: _isObscured
                                      ? '＊＊＊'
                                      : AppFmt.num(marketValue),
                                ),
                                const _HeroDivider(),
                                _HeroStat(
                                  label: '持倉檔數',
                                  value: positions
                                      .where((p) => p.quantity > 0)
                                      .length
                                      .toString(),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    Positioned( //右上角眼睛按鈕
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _isObscured = !_isObscured),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isObscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                SizedBox(
                  height: 200,
                  child: PageView(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [buildPage1(), buildPage2()],
                  ),
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
                            ? const Color(0xFF4A6FA5)
                            : const Color(0xFFE4E7ED),
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
                            color: Color(0xFFE4E7ED),
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
            MaterialPageRoute(
              builder: (_) => const AddTradeScreen(),
            ),
          );
          if (result != null) {
            tradeRepo.addTrade(result.trade);
            if (result.autoDeposit != null) {
              cashRepo.addFlow(result.autoDeposit!);
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Hero 卡片小元件 ─────────────────────────────
class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({
    required this.label,
    required this.value,
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 12),
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
            color: Color(0xFF1A1F2E),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A6FA5),
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
          border: Border.all(color: const Color(0xFFE4E7ED)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
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
                color: Color(0xFF5A6375),
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