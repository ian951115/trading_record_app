//定期定額畫面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/recurring_plan.dart';
import '../../repositories/recurring_repository.dart';
import '../../repositories/trade_repository.dart';
import '../../services/calc/recurring_service.dart';
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
              ...plans.map((plan) => _RecurringTile(
                plan: plan,
                trades: trades,
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

// ── 計畫 Tile ────────────────────────────────
class _RecurringTile extends StatefulWidget {
  final RecurringPlan plan;
  final List trades; //用於計算下次扣款
  const _RecurringTile({required this.plan, required this.trades});

  @override
  State<_RecurringTile> createState() => _RecurringTileState();
}

class _RecurringTileState extends State<_RecurringTile> {
  bool _expanded = false;

  Future<void> _confirmDelete(BuildContext context, RecurringRepository repo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('刪除「${widget.plan.name}」的定期定額計畫？\n已入帳的交易紀錄不受影響'),
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
    if (ok == true && context.mounted) repo.delete(widget.plan.id);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final repo = context.read<RecurringRepository>();
    final isPaused = !plan.isActive;
    final nextDate = RecurringService.nextScheduledDate(plan);
    final nextStr = nextDate == null ? '—' : '${nextDate.month}/${nextDate.day}';

    // 扣款日描述，e.g. "每月 5, 20 日"
    final dayStr = '每月 ${plan.dayOfMonth.join(", ")} 日';

    return Opacity(
      opacity: isPaused ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E7ED)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4, offset: const Offset(0, 1),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container( //左：股票代碼徽章
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isPaused
                          ? const Color(0xFFF0F2F5)
                          : const Color(0xFFEBF0F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        plan.symbol,
                        style: TextStyle(
                          fontSize: plan.symbol.length > 4 ? 9 : 11,
                          fontWeight: FontWeight.w700,
                          color: isPaused
                              ? AppColors.textMuted
                              : const Color(0xFF4A6FA5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  //中：名稱、頻率、暫停標籤
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                plan.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isPaused
                                      ? AppColors.textMuted
                                      : const Color(0xFF1A1F2E)
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPaused) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '暫停',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFE07B20),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$dayStr  ·  ${AppFmt.num(plan.amountPerTime)} 元/次',
                          style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column( //右：月金額 + 下次日期 + 選單
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${AppFmt.num(plan.monthlyAmount)}/月',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isPaused
                              ? AppColors.textMuted
                              : const Color(0xFF4A6FA5),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isPaused ? '—' : '下次：$nextStr',
                        style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: const Icon(
                        Icons.expand_more,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // 暫停/恢復
                    Expanded(
                      child: GestureDetector(
                        onTap: () => repo.toggleActive(plan),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined,
                                size: 14,
                                color: const Color(0xFFE07B20),
                              ),
                              const SizedBox(width: 4),
                              Text(isPaused ? '恢復' : '暫停',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE07B20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 編輯
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddRecurringScreen(existingPlan: plan))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF0F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4A6FA5)),
                              SizedBox(width: 4),
                              Text(
                                '編輯',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A6FA5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 刪除
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _confirmDelete(context, repo),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF0EF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline,
                                size: 14,
                                color: AppColors.profit,
                              ),
                              SizedBox(width: 4),
                              Text('刪除',
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
              ],
            ],
          ),
        ),
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
