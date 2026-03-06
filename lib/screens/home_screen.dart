//主畫面UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trading_record_app/models/position.dart';
import 'package:trading_record_app/repositories/cash_flow_repository.dart';
import 'package:trading_record_app/repositories/trade_repository.dart';
import 'package:trading_record_app/screens/cash_flow_screen.dart';
import 'package:trading_record_app/services/portfolio_service.dart';
import '../widgets/home_menu_tile.dart';
import 'trade_list_screen.dart';
import 'position_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('交易紀錄'),
        centerTitle: true,
      ),
      
      body: Column(
        children: [
          Container(   //上方圖表佔位
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade100,
              borderRadius: BorderRadius.circular(16),   //四個角圓半徑
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('現金: $cash'),
                  Text('市值: ${marketValue.toStringAsFixed(2)}'),
                  Text('總資產: ${totalAsset.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),

          Expanded( //下方按鈕區   expanded代表撐滿剩下的空間
            child: GridView.count( //建立可滑動的2D矩陣
              crossAxisCount: 3, //每列的數量
              padding: const EdgeInsets.all(16), //外圍距離
              crossAxisSpacing: 16, //每欄間距
              mainAxisSpacing: 16, //每列間距
              children: [
                HomeMenuTile(
                  icon: Icons.receipt_long,
                  label: '交易明細',
                  onTap: () { //導航用
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TradeListScreen()
                      ),
                    );
                  },
                ),
                HomeMenuTile(
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
                HomeMenuTile(
                  icon: Icons.calendar_month,
                  label: '收益日曆',
                  onTap: () {},
                ),
                HomeMenuTile(
                  icon: Icons.flag,
                  label: '年度目標',
                  onTap: () {},
                ),
                HomeMenuTile(
                  icon: Icons.show_chart,
                  label: '各式圖表',
                  onTap: () {},
                ),
                HomeMenuTile(
                  icon: Icons.savings,
                  label: '股利紀錄',
                  onTap: () {},
                ),
                HomeMenuTile(
                  icon: Icons.attach_money,
                  label: '資金管理',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CashFlowScreen(),
                      )
                    );
                  },
                ),
                HomeMenuTile(
                  icon: Icons.settings,
                  label: '設定',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}