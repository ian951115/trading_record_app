//資金管理頁面ui
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/cash_flow.dart';
import '../../repositories/cash_flow_repository.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/calc/portfolio_service.dart';
import '../../widgets/common/hero_card.dart';
import '../../widgets/common/stats_strip.dart';
import '../../widgets/common/expanded_actions.dart';
import '../../widgets/tiles/cash_flow_tile.dart';
import 'add_cash_flow_screen.dart';

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
    final netCash = totalDeposit - totalWithdraw;

    //資金水位（現金 / 淨入金）
    final waterLevel = netCash == 0 ? 0.0 : (cash / netCash).clamp(0.0, 1.0);
    final waterPct = (waterLevel * 100).toStringAsFixed(1);
    final settingsRepo = context.watch<SettingsRepository>();
    final threshold = settingsRepo.isReady
        ? settingsRepo.settings.waterLevelThreshold
        : 0.3;
    final isLow = waterLevel < threshold;

    final cashColor = cash >= 0
        ? AppColors.textPrimary
        : AppColors.profit;

    return Scaffold(
      appBar: AppBar(title: const Text('資金管理')),
      body: Column(
        children: [
          // ── Hero 卡片 ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: HeroCard(
              title: '可用現金',
              colors: const [Color(0xFF2D6A4F), AppColors.loss],
              mainValue: Text(
                AppFmt.num(cash),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              stats: [
                HeroStat(label: '總入金', value: AppFmt.num(totalDeposit)),
                HeroStat(label: '總提領', value: AppFmt.num(totalWithdraw)),
                HeroStat(label: '淨資金', value: AppFmt.num(netCash)),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              children: [
                // ── 資金水位 ───────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )],
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
                              color: AppColors.textSecond,
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
                                    color: AppColors.profit,
                                  ),
                                ),
                              Text(
                                '$waterPct%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isLow
                                      ? AppColors.profit
                                      : AppColors.primary,
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
                          backgroundColor: AppColors.scaffoldBg,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isLow ? AppColors.profit : AppColors.primary),
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
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            isLow ? '⚠️ 水位偏低（低於 ${threshold * 100}%）' : '水位正常',
                            style: TextStyle(
                              fontSize: 10,
                              color: isLow ? AppColors.profit : AppColors.textMuted,
                            ),
                          ),
                          Text(
                            AppFmt.num(netCash),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
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
                      value: AppFmt.num(cash),
                      valueColor: cashColor,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

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
                            color: AppColors.border,
                          ),
                          SizedBox(height: 12),
                          Text(
                            '尚無資金紀錄',
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
                  ...cashFlows.map((flow) => CashFlowTile(
                    flow: flow,
                    onDelete: () async {
                      if (await ExpandedActions.confirmDelete(context)) {
                        cashRepo.removeFlow(flow.id);
                      }
                    },
                    onEdit: () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => AddCashFlowScreen(existingFlow: flow)),
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddCashFlowScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}