//庫存明細ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/trade_repository.dart';
import '../services/position_service.dart';
import '../widgets/position_tile.dart';
import '../widgets/position_summary.dart';

class PositionListScreen extends StatefulWidget {
  const PositionListScreen({super.key});

  @override
  State<PositionListScreen> createState() => _PositionListScreenState();
}

class _PositionListScreenState extends State<PositionListScreen> {
  double _rotationTurns = 0;

  void _refresh() {
    setState(() {
      _rotationTurns +=1;
      //未來接API
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final repository = context.watch<TradeRepository>();
    final trades = repository.getAllTrades();

    final result = buildPositions(trades); //庫存(包含剩餘股數=0)
    final allPositions = result.positions;
    final openPositions = allPositions.where((p) => p.quantity > 0).toList(); //庫存(>0)

    final totalMarketValue = openPositions.fold(0.0, (sum, p) => sum + p.marketValue);
    final totalCost = openPositions.fold(0.0, (sum, p) => sum + p.totalCost);
    final totalUnrealized = totalMarketValue - totalCost;
    final double totalReturn = totalCost == 0 ? 0 : (totalUnrealized / totalCost) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('庫存明細'),
      ),
      body: Column(
        children: [
          PositionSummary(
            totalCost: totalCost,
            totalMarketValue: totalMarketValue,
            totalUnrealized: totalUnrealized,
            totalReturn: totalReturn,
            rotationTurns: _rotationTurns,
            onRefresh: _refresh,
          ),

          Expanded(
            child: ListView.separated(
              itemCount: openPositions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final position = openPositions[index];
                return PositionTile(position: position);
              }
            )
          )
        ]
      ),
    );
  }
}