//定期定額畫面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../repositories/recurring_repository.dart';
import '../../repositories/trade_repository.dart';
import '../../services/calc/recurring_service.dart';
import '../../widgets/common/expanded_actions.dart';
import '../../widgets/tiles/recurring_tile.dart';
import 'add_recurring_screen.dart';
import 'confirm_recurring_screen.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recurringRepo = context.watch<RecurringRepository>();
    final tradeRepo = context.watch<TradeRepository>();
    final plans = recurringRepo.getAll();
    final trades = tradeRepo.getAllTrades();

    //計算待確認總筆數（只算啟用的計畫）
    final pendingCount = RecurringService.getAllPendingEntries(
      activePlans: recurringRepo.getActive(),
      allTrades: trades,
    ).length;

    //每月總投入金額
    final monthlyTotal = recurringRepo.getActive()
        .fold(0.0, (s, p) => s + p.monthlyAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('定期定額'),
        actions: [
          Stack( //右上角補帳確認按鈕（有待確認時顯示紅點）
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.task_alt_outlined),
                tooltip: '補帳確認',
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const ConfirmRecurringScreen(),
                  ),
                ),
              ),
              if (pendingCount > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.profit,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: plans.isEmpty
          ? _EmptyState()
          : ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // ── 月投入統計卡 ────────────────
              if (monthlyTotal > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF0F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC5D4EC)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '每月預計投入',
                        style: TextStyle(
                          fontSize: 13, color: Color(0xFF5A6375),
                        ),
                      ),
                      Text('${AppFmt.num(monthlyTotal)}元',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3D5A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── 待確認提示橫幅 ──────────────
              if (pendingCount > 0) ...[
                GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => const ConfirmRecurringScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF0EF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF5C4C2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.profit, size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '有 $pendingCount 筆定期定額待確認',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.profit,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.profit,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            '去入帳 →',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── 計畫列表 ────────────────────
              const _SectionLabel(text: '計畫列表'),
              const SizedBox(height: 8),
              ...plans.map((plan) => RecurringTile(
                plan: plan,
                trades: trades,
                onDelete: () async {
                  if (await ExpandedActions.confirmDelete(context)) {
                    recurringRepo.delete(plan.id);
                  }
                },
                onEdit: () => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => AddRecurringScreen(existingPlan: plan)),
                ),
              )),
              const SizedBox(height: 80),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(
            builder: (_) => const AddRecurringScreen(),
          )),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── 空狀態 ───────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat_outlined,
            size: 56, color: Color(0xFFE4E7ED),
          ),
          const SizedBox(height: 14),
          const Text(
            '尚無定期定額計畫',
            style: TextStyle(fontSize: 15, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          const Text(
            '點擊右下角 + 新增第一個計畫',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── 區塊小標 ─────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1A1F2E),
    ),
  );
}