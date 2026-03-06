//出入金管理頁面ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cash_flow.dart';
import '../repositories/cash_flow_repository.dart';
import '../repositories/trade_repository.dart';
import '../screens/add_cash_flow_screen.dart';
import '../services/portfolio_service.dart';
import 'package:intl/intl.dart';

class CashFlowScreen extends StatelessWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cashRepo = context.watch<CashFlowRepository>();
    final tradeRepo = context.watch<TradeRepository>();

    final trades = tradeRepo.getAllTrades();
    final cashFlows = cashRepo.getAllFlows();

    final cash = PortfolioService.calculateCash(
      trades: trades,
      cashFlows: cashFlows,
    );

    final totalDeposit = cashRepo.totalDeposit;
    final totalWithdraw = cashRepo.totalWithdraw;

    return Scaffold(
      appBar: AppBar(
        title: const Text('資金管理'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container( //現金餘額區
            padding: const EdgeInsets.all(16),
            child: Text(
              '目前現金: ${cash.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text('總入金'),
                  Text(
                    totalDeposit.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('總提領'),
                  Text(
                    totalWithdraw.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('淨資金'),
                  Text(
                    (totalDeposit - totalWithdraw).toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),

          Expanded( //現金流量表
            child: cashFlows.isEmpty
                ? const Center(
                    child: Text(
                      '尚無資金紀錄',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: cashFlows.length,
                    itemBuilder: (context, index) {
                      final flow = cashFlows[index];
                      final formattedDate = DateFormat('yyyy-MM-dd').format(flow.date);

                      return Dismissible(
                        key: ValueKey(flow.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await context.read<CashFlowRepository>().removeFlow(flow.id);
                        },
                        child: ListTile(
                          title: Text(flow.type == CashFlowType.deposit ? '入金' : '提領'),
                          subtitle: Text(formattedDate),
                          trailing: Text( //右邊
                            flow.netAmount.toStringAsFixed(2),
                            style: TextStyle(
                              color: flow.type == CashFlowType.deposit
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddCashFlowScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}