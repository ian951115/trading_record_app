//目標追蹤頁面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../models/goal_type.dart';
import '../../models/trade.dart';
import '../../models/annual_goal.dart';
import '../../models/custom_goal.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/annual_goal_repository.dart';
import '../../repositories/custom_goal_repository.dart';
import '../../core/goal_pnl_helper.dart';
import '../goals/add_goal_screen.dart';

class GoalTrackingScreen extends StatefulWidget {
  const GoalTrackingScreen({super.key});

  @override
  State<GoalTrackingScreen> createState() => _GoalTrackingScreenState();
}

class _GoalTrackingScreenState extends State<GoalTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
 
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {})); // 讓FAB隨Tab切換
  }
 
  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }
 
  void _onFab() { //新增計畫
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddGoalScreen(),
    ));
  }
 
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('目標追蹤'),
      bottom: TabBar(
        controller: _tab,
        tabs: const [Tab(text: '年度目標'), Tab(text: '自訂義目標')],
      ),
    ),
    body: TabBarView(
      controller: _tab,
      children: const [_AnnualTab(), _CustomTab()],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _onFab,
      child: const Icon(Icons.add),
    ),
  );
}

// ══════════════════════════════════════════════════════
// 年度目標 Tab
// ══════════════════════════════════════════════════════
class _AnnualTab extends StatelessWidget {
  const _AnnualTab();
  @override
  Widget build(BuildContext context) {
    final goalRepo = context.watch<AnnualGoalRepository>();
    final tradeRepo = context.watch<TradeRepository>();
    final trades = tradeRepo.getAllTrades();
    final grouped = goalRepo.getGroupedByYear();
    final thisYear = DateTime.now().year;
    final current = grouped[thisYear] ?? []; //今年目標
    final histYears = grouped.keys //過往目標
        .where((y) => y != thisYear)
        .toList()..sort((a, b) => b.compareTo(a));
    final showBanner = _shouldShowBanner(current, trades);
 
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (showBanner) _BannerWidget(goals: current, trades: trades),
        if (current.isEmpty) // 當年
          const _AnnualEmptyHint()
        else
          ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${DateTime.now().year} 年',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.06,
                    ),
                  ),
                  Text(
                    '${current.length} 個目標',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            ...current.map((g) => _AnnualGoalCard(goal: g, trades: trades)),
          ],
        const SizedBox(height: 8),
        if (histYears.isNotEmpty) // 歷史折疊
          _HistorySection(years: histYears, grouped: grouped, trades: trades),
        const SizedBox(height: 80),
      ],
    );
  }
 
  bool _shouldShowBanner(List<AnnualGoal> goals, List<Trade> trades) { //提示欄顯示邏輯
    final month = DateTime.now().month;
    if (month < 11 || goals.isEmpty) return false; //11月以前不顯示
    return goals.any((g) { //已達成目標不顯示
      final pnl = GoalPnlHelper.calc(
        trades: trades,
        startDate: DateTime(g.year, 1, 1),
        endDate: DateTime(g.year, 12, 31),
        stockSymbol: g.goalType == GoalType.stockPnL ? g.stockSymbol : null,
      );
      return pnl < g.targetPnL;
    });
  }
}

// ── 歷史折疊區塊 ─────────────────────────────────────
class _HistorySection extends StatefulWidget {
  final List<int> years;
  final Map<int, List<AnnualGoal>> grouped;
  final List<Trade> trades;
  const _HistorySection({
    required this.years,
    required this.grouped,
    required this.trades,
  });

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  late final Map<int, bool> _yearOpen; //記錄每個年份是否展開

  @override
  void initState() {
    super.initState();
    // 預設全部收合，最近一年預設展開
    _yearOpen = {for (final y in widget.years) y: y == widget.years.first};
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row( //歷史紀錄區標頭
          children: [
            const Text(
              '📂  我的紀錄',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecond,
              ),
            ),
            const Spacer(),
            Text( //顯示共有幾年
              '${widget.years.length} 年紀錄',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      
      ...widget.years.map((y) {
        final isYearOpen = _yearOpen[y] ?? false;
        final goals = widget.grouped[y]!;
        final doneCount = goals.where((g) {
          final pnl = GoalPnlHelper.calc(
            trades: widget.trades,
            startDate: DateTime(y, 1, 1),
            endDate: DateTime(y, 12, 31),
            stockSymbol: g.goalType == GoalType.stockPnL ? g.stockSymbol : null,
          );
          return pnl >= g.targetPnL;
        }).length;

        return Column(
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _yearOpen[y] = !isYearOpen),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row( //年分標頭
                  children: [
                    Text(
                      '$y 年',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecond,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container( // 達成率小 badge
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: doneCount == goals.length
                            ? const Color(0xFFF2FBF6)
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$doneCount/${goals.length} 達成',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: doneCount == goals.length
                              ? AppColors.loss
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isYearOpen ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (isYearOpen) //展開後顯示該年的卡片
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: goals.map((g) =>
                    _AnnualGoalCard(goal: g, trades: widget.trades),
                  ).toList(),
                ),
              ),
          ],
        );
      }),
    ],
  );
}

// ── 年度目標卡片 ─────────────────────────────
class _AnnualGoalCard extends StatefulWidget {
  final AnnualGoal goal;
  final List<Trade> trades;
  const _AnnualGoalCard({required this.goal, required this.trades});

  @override
  State<_AnnualGoalCard> createState() => _AnnualGoalCardState();
}

class _AnnualGoalCardState extends State<_AnnualGoalCard> {
  bool _expanded = false;

  // 標題：totalPnL 固定文字，個股顯示名稱+代號
  String get _title => widget.goal.goalType == GoalType.totalPnL
      ? '📊 總損益目標'
      : '${widget.goal.stockName ?? widget.goal.stockSymbol ?? '個股'}'
        '（${widget.goal.stockSymbol ?? ''}）';

  // 損益計算
  double _calcPnL() => GoalPnlHelper.calc(
    trades: widget.trades,
    startDate: DateTime(widget.goal.year, 1, 1),
    endDate: DateTime(widget.goal.year, 12, 31),
    stockSymbol: widget.goal.goalType == GoalType.stockPnL
        ? widget.goal.stockSymbol
        : null,
  );

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('刪除 ${widget.goal.year} 年「$_title」目標？'),
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
      context.read<AnnualGoalRepository>().delete(widget.goal.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final now = DateTime.now();
    final pnl = _calcPnL();
    final progress = goal.targetPnL <= 0
        ? 0.0
        : (pnl / goal.targetPnL).clamp(0.0, 1.0);
    final isThisYear = goal.year == now.year;
    final isFuture = goal.year > now.year;
    final isDone = pnl >= goal.targetPnL;
    final isFailed = !isThisYear && !isFuture && !isDone; //過去年份且未達成

    //顏色主題
    Color barColor, bgColor, borderColor;
    String badgeText;
    Color badgeBg, badgeFg;
    if (isFuture) {
      barColor    = AppColors.textMuted;
      bgColor     = Colors.white;
      borderColor = AppColors.border;
      badgeText   = '尚未開始';
      badgeBg     = AppColors.cardBg;
      badgeFg     = AppColors.textMuted;
    } else if (isDone) {
      barColor    = AppColors.loss;
      bgColor     = const Color(0xFFF2FBF6);
      borderColor = AppColors.lossBorder;
      badgeText   = '✓ 達成';
      badgeBg     = AppColors.loss;
      badgeFg     = Colors.white;
    } else if (isFailed) {
      barColor    = AppColors.profit;
      bgColor     = const Color(0xFFFDF5F5);
      borderColor = AppColors.profitBorder;
      badgeText   = '✗ 未達成';
      badgeBg     = AppColors.profitBg;
      badgeFg     = AppColors.profit;
    } else { // 進行中
      barColor    = AppColors.primary;
      bgColor     = Colors.white;
      borderColor = AppColors.border;
      badgeText   = '進行中';
      badgeBg     = AppColors.primaryLight;
      badgeFg     = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
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
                Expanded(
                  child: Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F2E),
                    ),
                    overflow: TextOverflow.ellipsis,
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
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeFg,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.expand_more,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            // 副標：年份範圍
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  goal.goalType == GoalType.totalPnL ? '累計損益' : '個股損益',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: CircleAvatar(
                    radius: 1.5,
                    backgroundColor: AppColors.border,
                  ),
                ),
                Text(
                  '${goal.year}/01/01 – ${goal.year}/12/31',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 損益 vs 目標
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '已實現損益',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFmt.pnl(pnl),
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
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFmt.num(goal.targetPnL),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 進度條
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),

            const SizedBox(height: 6),

            // 進度百分比 + 備註
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
                  Flexible(
                    child: Text(
                      goal.note!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),

            // 展開：編輯 / 刪除
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,MaterialPageRoute(
                        builder: (_) => AddGoalScreen(
                          initialMode: GoalMode.annual,
                          existingAnnual: goal,
                        ),
                      )),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF0F8),
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
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _confirmDelete(context),
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
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// 自訂義目標 Tab
// ══════════════════════════════════════════════════════
class _CustomTab extends StatefulWidget {
  const _CustomTab();

  @override
  State<_CustomTab> createState() => _CustomTabState();
}

class _CustomTabState extends State<_CustomTab> {
  CustomGoalStatus? _filter;  // null = 全部
 
  @override
  Widget build(BuildContext context) {
    final goalRepo = context.watch<CustomGoalRepository>();
    final tradeRepo = context.watch<TradeRepository>();
    final trades = tradeRepo.getAllTrades();
    final all = goalRepo.getAll();
 
    // 計算每個 goal 的 pnl + status
    final withStatus = all.map((g) {
      final pnl = GoalPnlHelper.calc(
        trades: trades,
        startDate: g.startDate,
        endDate: g.endDate,
        stockSymbol: g.goalType == GoalType.stockPnL ? g.stockSymbol : null,
      );
      return (goal: g, pnl: pnl, status: g.getStatus(pnl));
    }).toList();
 
    final filtered = _filter == null
        ? withStatus
        : withStatus.where((e) => e.status == _filter).toList();
 
    return Column(
      children: [
        _FilterChips(
          current: _filter,
          onChanged: (v) => setState(() => _filter = v),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const _CustomEmptyHint()
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _CustomGoalCard(
                  goal: filtered[i].goal,
                  pnl: filtered[i].pnl,
                  status: filtered[i].status,
                ),
              ),
        ),
      ],
    );
  }
}

// ── 篩選 Chips ───────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final CustomGoalStatus? current;
  final ValueChanged<CustomGoalStatus?> onChanged;

  const _FilterChips({required this.current, required this.onChanged});
 
  static const _labels = <CustomGoalStatus?, String>{
    null: '全部',
    CustomGoalStatus.ongoing: '進行中',
    CustomGoalStatus.achieved: '已達成',
    CustomGoalStatus.ended: '已結束',
  };
 
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
    child: Row(
      children: _labels.entries.map((e) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(e.value),
          selected: current == e.key,
          onSelected: (_) => onChanged(e.key),
        ),
      )).toList(),
    ),
  );
}

// ── 自訂目標卡片 ─────────────────────────────
class _CustomGoalCard extends StatefulWidget {
  final CustomGoal goal;
  final double pnl;
  final CustomGoalStatus status;
  const _CustomGoalCard({
    required this.goal,
    required this.pnl,
    required this.status,
  });

  @override
  State<_CustomGoalCard> createState() => _CustomGoalCardState();
}

class _CustomGoalCardState extends State<_CustomGoalCard> {
  bool _expanded = false;

  // 格式化日期為 yyyy/MM/dd
  String _fmt(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  // 副標題：標的說明
  String get _subtitle {
    if (widget.goal.goalType == GoalType.totalPnL) return '累計總損益';
    final name = widget.goal.stockName ?? widget.goal.stockSymbol ?? '個股';
    final symbol = widget.goal.stockSymbol ?? '';
    return '個股損益・$name（$symbol）';
  }

  // Badge widget（依狀態 + 剩餘天數）
  Widget _buildBadge() {
    final goal = widget.goal;
    switch (widget.status) {
      case CustomGoalStatus.achieved:
        return _badge(
          '✓ 達成',
          bg: AppColors.loss,
          fg: Colors.white,
        );
      case CustomGoalStatus.ended:
        return _badge(
          '✗ 已結束',
          bg: AppColors.profitBg,
          fg: AppColors.profit,
        );
      case CustomGoalStatus.ongoing:
        if (goal.daysLeft <= 7) {
          return _badge(
            '⚠ 還有 ${goal.daysLeft} 天',
            bg: const Color(0xFFFEF4EC),
            fg: const Color(0xFFE07B2A),
          );
        }
        return _badge(
          '進行中',
          bg: const Color(0xFFEBF0F8),
          fg: const Color(0xFF4A6FA5),
        );
    }
  }

  Widget _badge(String text, {required Color bg, required Color fg}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      );

  // 卡片背景色依狀態
  Color get _bgColor {
    switch (widget.status) {
      case CustomGoalStatus.achieved: return const Color(0xFFF2FBF6);
      case CustomGoalStatus.ended: return const Color(0xFFFDF5F5);
      case CustomGoalStatus.ongoing: return Colors.white;
    }
  }

  Color get _borderColor {
    switch (widget.status) {
      case CustomGoalStatus.achieved: return AppColors.lossBorder;
      case CustomGoalStatus.ended: return AppColors.profitBorder;
      case CustomGoalStatus.ongoing: return AppColors.border;
    }
  }

  Color get _barColor {
    switch (widget.status) {
      case CustomGoalStatus.achieved: return AppColors.loss;
      case CustomGoalStatus.ended: return AppColors.profit;
      case CustomGoalStatus.ongoing: return const Color(0xFF4A6FA5);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('刪除「${widget.goal.title}」？'),
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
      context.read<CustomGoalRepository>().delete(widget.goal.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final pnl = widget.pnl;
    final progress = goal.targetAmount <= 0
        ? 0.0
        : (pnl / goal.targetAmount).clamp(0.0, 1.0);
    
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //第一行：標題 + badge + 箭頭
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F2E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildBadge(),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.expand_more,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            // 副標：標的 + 日期範圍
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: CircleAvatar(radius: 1.5, backgroundColor: AppColors.border),
                ),
                Text(
                  '${_fmt(goal.startDate)} – ${_fmt(goal.endDate)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 損益 vs 目標
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '已實現損益',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFmt.pnl(pnl),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _barColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '目標',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFmt.num(goal.targetAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 進度條
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(_barColor),
              ),
            ),

            const SizedBox(height: 6),

            // 進度百分比 + 備註
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _barColor,
                  ),
                ),
                if (goal.note?.isNotEmpty == true)
                  Flexible(
                    child: Text(
                      goal.note!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),

            // 展開：編輯 / 刪除
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,MaterialPageRoute(
                        builder: (_) => AddGoalScreen(
                          initialMode: GoalMode.custom,
                          existingCustom: goal,
                        ),
                      )),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF0F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: Color(0xFF4A6FA5),
                            ),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _confirmDelete(context),
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
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// 共用小 Widgets
// ══════════════════════════════════════════════════════
class _BannerWidget extends StatelessWidget { //提示欄
  final List<AnnualGoal> goals;
  final List<Trade> trades;
  const _BannerWidget({required this.goals, required this.trades});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF4EC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFF5D5A8)),
    ),
    child: Row(
      children: [
        const Text('🔔', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('年底將至，確認目標進度！',
            style: TextStyle(fontSize: 12, color: Color(0xFFB35A00)),
          ),
        ),
      ],
    ),
  );
}

class _AnnualEmptyHint extends StatelessWidget {
  const _AnnualEmptyHint();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 48, color: AppColors.border),
          SizedBox(height: 12),
          Text('尚無年度目標', style: TextStyle(color: AppColors.textMuted)),
          SizedBox(height: 6),
          Text(
            '點擊右下角 + 新增',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _CustomEmptyHint extends StatelessWidget {
  const _CustomEmptyHint();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.track_changes_outlined, size: 48, color: AppColors.border),
        SizedBox(height: 12),
        Text('尚無自訂義目標', style: TextStyle(color: AppColors.textMuted)),
        SizedBox(height: 6),
        Text(
          '點擊右下角 + 新增',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}