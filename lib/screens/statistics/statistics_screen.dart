//歷史之最畫面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/cash_flow_repository.dart';
import '../../services/calc/statistics_service.dart';
import '../../widgets/common/hero_card.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  String _fmtDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2,"0")}/${d.day.toString().padLeft(2,"0")}';

  @override
  Widget build(BuildContext context) {
    final trades = context.watch<TradeRepository>().getAllTrades();
    final cashFlows = context.watch<CashFlowRepository>().getAllFlows();
    final stats = StatisticsService.calculate(
      trades: trades, cashFlows: cashFlows,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('我的歷史之最')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── Hero 卡片 ──────────────────────────
          HeroCard(
            title: '交易生涯總覽',
            mainValue: Text(
              AppFmt.pnl(stats.totalRealizedPnL),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            stats: [
              HeroStat(label: '交易天數', value: '${stats.totalTradingDays}天'),
              HeroStat(label: '總結清比數', value: '${stats.sellCount}筆'),
              HeroStat(
                label: '整體勝率',
                value: '${(stats.winRate * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── 損益紀錄 ────────────────────────────
          _SectionTitle(title: '損益紀錄'),
          const SizedBox(height: 8),

          if (stats.bestTrade != null)
            _HistTile(
              icon: Icons.emoji_events_outlined,
              iconBg: AppColors.profitBg,
              iconColor: AppColors.profit,
              title: '最大單筆獲利',
              value: AppFmt.pnl(stats.bestTrade!.pnl),
              valueColor: AppColors.profit,
              subtitle:
                  '${stats.bestTrade!.name} (${stats.bestTrade!.symbol})  '
                  '· ${_fmtDate(stats.bestTrade!.date)}',
            ),
          
          const SizedBox(height: 8),

          if (stats.worstTrade != null)
            _HistTile(
              icon: Icons.trending_down_rounded,
              iconBg: AppColors.lossBg,
              iconColor: AppColors.loss,
              title: '最大單筆虧損',
              value: AppFmt.num(stats.worstTrade!.pnl),
              valueColor: AppColors.loss,
              subtitle:
                  '${stats.worstTrade!.name} (${stats.worstTrade!.symbol})  '
                  '· ${_fmtDate(stats.worstTrade!.date)}',
            ),

          const SizedBox(height: 8),

          if (stats.bestReturnSymbol != null)
            _HistTile(
              icon: Icons.trending_up_rounded,
              iconBg: AppColors.primaryLight,
              iconColor: AppColors.primary,
              title: '最高報酬率個股',
              value: '+${stats.bestReturnRate.toStringAsFixed(1)}%',
              valueColor: AppColors.profit,
              subtitle:
                  '${stats.bestReturnName} (${stats.bestReturnSymbol})'
                  '${stats.bestReturnIsOpen ? "  · 持倉中" : ""}',
            ),
          
          const SizedBox(height: 16),

          // ── 連勝/連敗 ──────────────────────────
          _SectionTitle(title: '連勝 / 連敗'),
          const SizedBox(height: 8),
          _StatsStrip2(
            left: _StripCell(
              label: '最長連勝 🔥',
              value: '${stats.maxWinStreak} 筆',
              valueColor: AppColors.profit,
            ),
            right: _StripCell(
              label: '最長連敗 ❄️',
              value: '${stats.maxLossStreak} 筆',
              valueColor: AppColors.loss,
            ),
          ),

          const SizedBox(height: 16),

          // ── 持倉紀錄 ────────────────────────────
          _SectionTitle(title: '持倉紀錄'),
          const SizedBox(height: 8),
          if (stats.longestHoldingSymbol != null)
           _HistTile(
            icon: Icons.hourglass_bottom_rounded,
            iconBg: AppColors.primaryLight,
            iconColor: AppColors.primary,
            title: '最長持有',
            value: '${stats.longestHoldingDays} 天',
            valueColor: AppColors.primary,
            subtitle: '${stats.longestHoldingName} (${stats.longestHoldingSymbol})',
           )
          else _EmptyHint(text: '尚無持倉紀錄'),

          const SizedBox(height: 16),

          // ── 進階統計 ────────────────────────────
          _SectionTitle(title: '進階統計'),
          const SizedBox(height: 8),
          _StatsStrip2(
            left: _StripCell(
              label: '期望值 (Expectancy)',
              value: AppFmt.pnl(stats.expectancy),
              valueColor: AppColors.pnl(stats.expectancy),
            ),
            right: _StripCell(
              label: '最大回撤 (Max Drop Down)',
              value: '${stats.maxDrawdownPct.toStringAsFixed(1)}%',
              valueColor: stats.maxDrawdownPct < 0
                  ? AppColors.loss
                  : AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── 區塊標題 ────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(title,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );
}

// ── 單筆紀錄 Tile ────────────────────────────────
class _HistTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, value;
  final Color valueColor;
  final String? subtitle;

  const _HistTile({
    required this.icon, required this.iconBg,
    required this.iconColor, required this.title,
    required this.value, required this.valueColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4, offset: const Offset(0, 1),
        )],
      ),
      child: Row(
        children: [
          Container( //左側圖示
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded( //右側文字
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2格統計列 ───────────────────────────────────
class _StripCell { //資料/格式
  final String label, value;
  final Color valueColor;
  const _StripCell({required this.label, required this.value, required this.valueColor});
}

class _StatsStrip2 extends StatelessWidget { //兩格的排版關係
  final _StripCell left, right;
  const _StatsStrip2({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _Cell(cell: left, isLeft: true)),
          Container(width: 1, height: 56, color: AppColors.border),
          Expanded(child: _Cell(cell: right, isLeft: false)),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget { //單格畫面
  final _StripCell cell;
  final bool isLeft;
  const _Cell({required this.cell, required this.isLeft});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: isLeft ? const Radius.circular(12) : Radius.zero,
        bottomLeft: isLeft ? const Radius.circular(12) : Radius.zero,
        topRight: isLeft ? Radius.zero : const Radius.circular(12),
        bottomRight: isLeft ? Radius.zero : const Radius.circular(12),
      ),
    ),
    child: Column(
      children: [
        Text(
          cell.label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cell.value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cell.valueColor,
          ),
        ),
      ],
    ),
  );
}

// ── 空狀態提示 ──────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      ),
    ),
  );
}
