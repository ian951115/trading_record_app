//主畫面UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/position.dart';
import '../repositories/cash_flow_repository.dart';
import '../repositories/trade_repository.dart';
import '../screens/cash_flow_screen.dart';
import '../services/portfolio_service.dart';
import 'trade_list_screen.dart';
import 'position_list_screen.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/portfolio_summary.dart';
import '../models/trade.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    final tradeRepo = context.watch<TradeRepository>();
    final cashRepo = context.watch<CashFlowRepository>();

    final trades = tradeRepo.getAllTrades();
    final cashFlows = cashRepo.getAllFlows();

    final positions = buildPositions(trades);

    final cash = PortfolioService.calculateCash(
      trades: trades,
      cashFlows: cashFlows,
    );

    final marketValue =
        PortfolioService.calculateMarketValue(positions);
    
    final totalAsset =
        PortfolioService.calculateTotalAsset(
          cash: cash,
          positions: positions,
        );

    final recentTrades = trades.take(5).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('交易紀錄'),
            centerTitle: true,
            pinned: true, //往上滑後 AppBar 會固定在頂部
            expandedHeight: 120, //展開高度
          ),

          SliverToBoxAdapter(
            child: PortfolioSummary(
              cash: _isObscured ? 0 : cash,
              marketValue: _isObscured ? 0 : marketValue,
              totalAsset: _isObscured ? 0 : totalAsset,
              isObscured: _isObscured,
              onToggleObscure: () {
                setState(() {
                  _isObscured = !_isObscured;
                });
              },
            ),
          ),

          SliverToBoxAdapter( //中間按鈕區(橫向滑動)
            child: Column(
              children: [
                SizedBox(
                  height: 100,
                  child: ListView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      QuickActionTile(
                        icon: Icons.receipt_long,
                        label: '交易明細',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TradeListScreen()
                            ),
                          );
                        },
                      ),
                      QuickActionTile(
                        icon: Icons.inventory,
                        label: '庫存明細',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PositionListScreen()
                            ),
                          );
                        },
                      ),
                      QuickActionTile(
                        icon: Icons.calendar_month,
                        label: '收益日曆',
                        onTap: () {},
                      ),
                      QuickActionTile(
                        icon: Icons.flag,
                        label: '年度目標',
                        onTap: () {},
                      ),
                      QuickActionTile(
                        icon: Icons.show_chart,
                        label: '各式圖表',
                        onTap: () {},
                      ),
                      QuickActionTile(
                        icon: Icons.savings,
                        label: '股利紀錄',
                        onTap: () {},
                      ),
                      QuickActionTile(
                        icon: Icons.attach_money,
                        label: '資金管理',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CashFlowScreen()
                            )
                          );
                        },
                      ),
                      QuickActionTile(
                        icon: Icons.settings,
                        label: '設定',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                Padding( //滑動指示器
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SliverList( //最近交易
            delegate: SliverChildBuilderDelegate( //選他因為是Lazy build意思是只建立螢幕需要的widget，比SliverChildListDelegate 更好
              (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '最近交易',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final trade = recentTrades[index - 1];

                return ListTile(
                  leading: Icon(
                    trade.type == TradeType.buy
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: trade.type == TradeType.buy
                        ? Colors.red
                        : Colors.green,
                  ),
                  title: Text(trade.symbol),
                  subtitle: Text('${trade.type == TradeType.buy ? '買入' : '賣出'} ${trade.quantity} 股'),
                  trailing: Text(trade.price.toStringAsFixed(2)),
                );
              },

              childCount: recentTrades.length + 1,
            ),
          ),
        ],
      ),
    );
  }
}