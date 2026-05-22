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
import '../../widgets/common/hero_divider.dart';
import '../../widgets/common/stats_strip.dart';
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
                        AppColors.loss,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: AppColors.loss.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )],
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
                        AppFmt.num(cash),
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
                          _HeroStat(label: '總入金', value: AppFmt.num(totalDeposit)),
                          const HeroDivider(horizontalMargin: 12),
                          _HeroStat(label: '總提領', value: AppFmt.num(totalWithdraw)),
                          const HeroDivider(horizontalMargin: 12),
                          _HeroStat(label: '淨資金', value: AppFmt.num(netCash)),
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

                const SizedBox(height: 16),

                // ── 紀錄列表標題 ───────────────
                const Row(
                  children: [
                    Text(
                      '資金紀錄',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                  ...cashFlows.map((flow) => _CashFlowTile(flow: flow)),
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

// ── Hero 卡片小元件 ─────────────────────────────
class _HeroStat extends StatelessWidget {
  final String label, value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
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

// ── 資金紀錄列 ─────────────────────────────────
class _CashFlowTile extends StatefulWidget {
  final CashFlow flow;
  const _CashFlowTile({required this.flow});

  @override
  State<_CashFlowTile> createState() => _CashFlowTileState();
}

class _CashFlowTileState extends State<_CashFlowTile> {
  bool _expanded = false;

  void _onEdit(BuildContext context) { //跳到編輯畫面
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => AddCashFlowScreen(existingFlow: widget.flow)),
    );
  }

  Future<void> _onDelete(BuildContext context) async { //刪除確認
    final flow = widget.flow;
    final typeName = flow.type == CashFlowType.deposit ? '入金' : '提領';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除這筆$typeName紀錄？\n此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.profit),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<CashFlowRepository>().removeFlow(flow.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    final isDeposit = flow.type == CashFlowType.deposit;
    final dateStr = '${flow.date.year}/'
        '${flow.date.month.toString().padLeft(2,'0')}/'
        '${flow.date.day.toString().padLeft(2,'0')}';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _expanded
                ? AppColors.primary
                : AppColors.border,
            width: _expanded ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4, offset: const Offset(0, 1),
          )],
        ),
        child: Column(
          children: [
            // ── 主行（永遠顯示）──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container( //左側圖示
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isDeposit
                          ? AppColors.lossBg
                          : AppColors.profitBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDeposit
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 18,
                      color: isDeposit
                          ? AppColors.loss
                          : AppColors.profit,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          flow.note?.isNotEmpty == true
                              ? '$dateStr・${flow.note}'
                              : dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text( //右側金額
                    isDeposit
                        ? '+${AppFmt.num(flow.amount)}'
                        : '-${AppFmt.num(flow.amount)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDeposit
                          ? AppColors.loss
                          : AppColors.profit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation( //展開箭頭
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
  
            // ── 展開行（編輯/刪除按鈕）──────────
            if (_expanded) ...[
              Divider(
                height: 1,
                color: AppColors.border,
                indent: 14,
                endIndent: 14,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    Expanded( //編輯
                      child: GestureDetector(
                        onTap: () => _onEdit(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '編輯',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded( //刪除
                      child: GestureDetector(
                        onTap: () => _onDelete(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.profitBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: AppColors.profit,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '刪除',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.profit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}