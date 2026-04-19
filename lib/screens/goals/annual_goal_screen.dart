//年度目標頁面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/annual_goal.dart';
import '../../models/trade.dart';
import '../../repositories/annual_goal_repository.dart';
import '../../repositories/trade_repository.dart';
import '../../services/position_service.dart';
import 'add_goal_screen.dart';

class AnnualGoalScreen extends StatelessWidget {
  const AnnualGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goalRepo = context.watch<AnnualGoalRepository>();
    final tradeRepo = context.watch<TradeRepository>();
    final goals = goalRepo.getAll(); //依年份降序
    final trades = tradeRepo.getAllTrades();

    return Scaffold(
      appBar: AppBar(title: const Text('年度目標')),
      body: goals.isEmpty
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                ...goals.map((goal) => _GoalCard(
                  goal: goal,
                  trades: trades,
                )),
                const SizedBox(height: 80),
              ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddGoalScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── 年度目標卡片 ─────────────────────────────
class _GoalCard extends StatelessWidget {
  final AnnualGoal goal;
  final List<Trade> trades;

  const _GoalCard({required this.goal, required this.trades});

  // 計算該年已實現損益
  double _calcYearPnL() {
    final result = buildPositions(trades);
    final pnlMap = result.tradePnLMap;
    double total = 0;
    for (final t in trades) {
      if (t.type == TradeType.sell && t.date.year == goal.year) {
        total += pnlMap[t.id] ?? 0;
      }
    }
    return total;
  }

  void _onMenu(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AddGoalScreen(existingGoal: goal)),
        );
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('刪除 ${goal.year} 年度目標？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE8504A)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AnnualGoalRepository>().delete(goal.id);
    }
  }



  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final now = DateTime.now();
    final yearPnL = _calcYearPnL();
    final progress = goal.targetPnL <= 0
        ? 0.0
        : (yearPnL / goal.targetPnL).clamp(0.0, 1.0);
    final isThisYear = goal.year == now.year;
    final isDone = yearPnL >= goal.targetPnL;
    final isFailed = !isThisYear && !isDone; //過去年份且未達成
    final isPast = goal.year < now.year;

    //顏色主題
    Color barColor;
    Color bgColor;
    Color borderColor;
    String? badgeText;
    Color? badgeBg;
    Color? badgeFg;

    if (isDone) {
      barColor    = const Color(0xFF3D9E6B);
      bgColor     = const Color(0xFFF2FBF6);
      borderColor = const Color(0xFFB8DFC9);
      badgeText   = '✓ 達成';
      badgeBg     = const Color(0xFF3D9E6B);
      badgeFg     = Colors.white;
    } else if (isFailed) {
      barColor    = const Color(0xFFE8504A);
      bgColor     = const Color(0xFFFDF5F5);
      borderColor = const Color(0xFFF5C4C2);
      badgeText   = '✗ 未達成';
      badgeBg     = const Color(0xFFFDF0EF);
      badgeFg     = const Color(0xFFE8504A);
    } else {
      // 進行中
      barColor    = const Color(0xFF4A6FA5);
      bgColor     = Colors.white;
      borderColor = const Color(0xFFE4E7ED);
      badgeText   = '進行中';
      badgeBg     = const Color(0xFFEBF0F8);
      badgeFg     = const Color(0xFF4A6FA5);
    }

    final sign = yearPnL >= 0 ? '+' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 第一行：年份 + badge + 選單 ────
          Row(
            children: [
              Text(
                '${goal.year} 年',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F2E),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeFg,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Color(0xFF9AA3B2),
                ),
                onSelected: (v) => _onMenu(context, v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('編輯')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      '刪除',
                      style: TextStyle(color: Color(0xFFE8504A)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── 損益 vs 目標 ────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '已實現損益',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9AA3B2)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$sign${fmt.format(yearPnL.toInt())}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '目標',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9AA3B2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(goal.targetPnL.toInt()),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A6375),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── 進度條 ──────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE4E7ED),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),

          const SizedBox(height: 6),

          // ── 進度百分比 + 備註 ───────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: barColor,
                ),
              ),
              if (goal.note?.isNotEmpty == true)
                Text(
                  goal.note!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9AA3B2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 空狀態 ───────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.flag_outlined,
        size: 56, color: Color(0xFFE4E7ED)),
      const SizedBox(height: 14),
      const Text('尚無年度目標',
        style: TextStyle(fontSize: 15, color: Color(0xFF9AA3B2))),
      const SizedBox(height: 8),
      const Text('點擊右下角 + 設定今年目標',
        style: TextStyle(fontSize: 12, color: Color(0xFF9AA3B2))),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddGoalScreen())),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('新增目標'),
      ),
    ]),
  );
}
