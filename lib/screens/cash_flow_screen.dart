//資金管理頁面ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common/stats_strip.dart';
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
    final formatter = NumberFormat('#,###');

    final trades = tradeRepo.getAllTrades();
    final cashFlows = cashRepo.getAllFlows();

    final cash = PortfolioService.calculateCash(
      trades: trades,
      cashFlows: cashFlows,
    );
    final totalDeposit = cashRepo.totalDeposit;
    final totalWithdraw = cashRepo.totalWithdraw;
    final netCash = totalDeposit - totalWithdraw;

    //資金水位（現金 / 淨入金）
    final waterLevel = netCash == 0 ? 0.0 : (cash / netCash).clamp(0.0, 1.0);
    final waterPct = (waterLevel * 100).toStringAsFixed(1);
    final isLow = waterLevel < 0.3;

    final cashColor = cash >= 0
        ? const Color(0xFF1A1F2E)
        : const Color(0xFFE8504A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('資金管理'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [

                // ── Hero 卡片 ──────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient( //漸層
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2D6A4F),
                        Color(0xFF3D9E6B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3D9E6B).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '可用現金',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(cash.toInt()),
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
                      Row(
                        children: [
                          _HeroStat(
                            label: '總入金',
                            value: formatter.format(totalDeposit.toInt()),
                          ),
                          const _HeroDivider(),
                          _HeroStat(
                            label: '總提領',
                            value: formatter.format(totalWithdraw.toInt()),
                          ),
                          const _HeroDivider(),
                          _HeroStat(
                            label: '淨資金',
                            value: formatter.format(netCash.toInt()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── 資金水位 ───────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '資金水位',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5A6375),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            children: [
                              if (isLow)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.warning_rounded,
                                    size: 14,
                                    color: Color(0xFFE8504A),
                                  ),
                                ),
                              Text(
                                '$waterPct%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isLow
                                      ? const Color(0xFFE8504A)
                                      : const Color(0xFF4A6FA5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: waterLevel,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFF0F2F5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isLow
                                ? const Color(0xFFE8504A)
                                : const Color(0xFF4A6FA5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '0',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9AA3B2),
                            ),
                          ),
                          Text(
                            isLow ? '⚠️ 水位偏低（低於 30%）' : '水位正常',
                            style: TextStyle(
                              fontSize: 10,
                              color: isLow
                                  ? const Color(0xFFE8504A)
                                  : const Color(0xFF9AA3B2),
                            ),
                          ),
                          Text(
                            formatter.format(netCash.toInt()),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9AA3B2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── 統計列 ─────────────────────
                StatsStrip(
                  cells: [
                    StatCell(
                      label: '入金次數',
                      value: cashFlows
                          .where((f) => f.type == CashFlowType.deposit)
                          .length
                          .toString(),
                    ),
                    StatCell(
                      label: '提領次數',
                      value: cashFlows
                          .where((f) => f.type == CashFlowType.withdraw)
                          .length
                          .toString(),
                    ),
                    StatCell(
                      label: '現金餘額',
                      value: formatter.format(cash.toInt()),
                      valueColor: cashColor,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── 紀錄列表標題 ───────────────
                const Row(
                  children: [
                    Text(
                      '資金紀錄',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1F2E),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── 紀錄列表 ───────────────────
                if (cashFlows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 48,
                            color: Color(0xFFE4E7ED),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '尚無資金紀錄',
                            style: TextStyle(
                              color: Color(0xFF9AA3B2),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...cashFlows.map((flow) => _CashFlowTile(flow: flow)),
              ],
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ── 資金紀錄列 ─────────────────────────────────
class _CashFlowTile extends StatelessWidget {
  final CashFlow flow;

  const _CashFlowTile({required this.flow});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final isDeposit = flow.type == CashFlowType.deposit;
    final dateStr = '${flow.date.year}/${flow.date.month.toString().padLeft(0,'0')}/${flow.date.day.toString().padLeft(2,'0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
      child: Row(
        children: [
          Container( //左側圖示
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDeposit
                  ? const Color(0xFFEEF7F2)
                  : const Color(0xFFFDF0EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDeposit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 18,
              color: isDeposit
                  ? const Color(0xFF3D9E6B)
                  : const Color(0xFFE8504A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded( //中間：類型 + 日期
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit ? '入金' : '提領',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1F2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  flow.note?.isNotEmpty == true
                      ? '$dateStr・${flow.note}'
                      : dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9AA3B2),
                  ),
                ),
              ],
            ),
          ),
          Text( //右側金額
            isDeposit
                ? '+${formatter.format(flow.amount.toInt())}'
                : '-${formatter.format(flow.amount.toInt())}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDeposit
                  ? const Color(0xFF3D9E6B)
                  : const Color(0xFFE8504A),
            ),
          ),
        ],
      ),
    );
  }
}