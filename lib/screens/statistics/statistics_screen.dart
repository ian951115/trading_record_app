//歷史之最畫面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../repositories/trade_repository.dart';
import '../../repositories/cash_flow_repository.dart';
import '../../services/calc/statistics_service.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  Color _pnlColor(double v) {
    if (v > 0) return const Color(0xFFE8504A);
    if (v < 0) return const Color(0xFF3D9E6B);
    return const Color(0xFF9AA3B2);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2,"0")}/${d.day.toString().padLeft(2,"0")}';


  @override
  Widget build(BuildContext context) {
    final trades = context.watch<TradeRepository>().getAllTrades();
    final cashFlows = context.watch<CashFlowRepository>().getAllFlows();
    final stats = StatisticsService.calculate(
      trades: trades, cashFlows: cashFlows,
    );
    final fmt = NumberFormat('#,###');
    final pnlColor = _pnlColor(stats.totalRealizedPnL);

    return Scaffold(
      appBar: AppBar(title: const Text('我的歷史之最')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── Hero 卡片 ──────────────────────────
          _HeroCard(
            totalPnL: stats.totalRealizedPnL,
            tradingDays: stats.totalTradingDays,
            sellCount: stats.sellCount,
            winRate: stats.winRate,
          ),

          const SizedBox(height: 16),

          // ── 損益紀錄 ────────────────────────────
          _SectionTitle(title: '損益紀錄'),
          const SizedBox(height: 8),

          if (stats.bestTrade != null)
            _HistTile(
              icon: Icons.emoji_events_outlined,
              iconBg: const Color(0xFFFDF0EF),
              iconColor: const Color(0xFFE8504A),
              title: '最大單筆獲利',
              value: '+${fmt.format(stats.bestTrade!.pnl.toInt())}',
              valueColor: const Color(0xFFE8504A),
              subtitle:
                  '${stats.bestTrade!.name} (${stats.bestTrade!.symbol})  '
                  '· ${_fmtDate(stats.bestTrade!.date)}',
            ),
          
          const SizedBox(height: 8),

          if (stats.worstTrade != null)
            _HistTile(
              icon: Icons.trending_down_rounded,
              iconBg: const Color(0xFFEEF7F2),
              iconColor: const Color(0xFF3D9E6B),
              title: '最大單筆虧損',
              value: '${fmt.format(stats.worstTrade!.pnl.toInt())}',
              valueColor: const Color(0xFF3D9E6B),
              subtitle:
                  '${stats.worstTrade!.name} (${stats.worstTrade!.symbol})  '
                  '· ${_fmtDate(stats.worstTrade!.date)}',
            ),

          const SizedBox(height: 8),

          if (stats.bestReturnSymbol != null)
            _HistTile(
              icon: Icons.trending_up_rounded,
              iconBg: const Color(0xFFEBF0F8),
              iconColor: const Color(0xFF4A6FA5),
              title: '最高報酬率個股',
              value: '+${stats.bestReturnRate.toStringAsFixed(1)}%',
              valueColor: const Color(0xFFE8504A),
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
              valueColor: const Color(0xFFE8504A),
            ),
            right: _StripCell(
              label: '最長連敗 ❄️',
              value: '${stats.maxLossStreak} 筆',
              valueColor: const Color(0xFF3D9E6B),
            ),
          ),

          const SizedBox(height: 16),

          // ── 持倉紀錄 ────────────────────────────
          _SectionTitle(title: '持倉紀錄'),
          const SizedBox(height: 8),
          if (stats.longestHoldingSymbol != null)
           _HistTile(
            icon: Icons.hourglass_bottom_rounded,
            iconBg: const Color(0xFFEBF0F8),
            iconColor: const Color(0xFF4A6FA5),
            title: '最長持有',
            value: '${stats.longestHoldingDays} 天',
            valueColor: const Color(0xFF4A6FA5),
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
              value: '${stats.expectancy >= 0 ? '+' : ''}'
                  '${fmt.format(stats.expectancy.toInt())}',
              valueColor: _pnlColor(stats.expectancy),
            ),
            right: _StripCell(
              label: '最大回撤 (Max Drop Down)',
              value: '${stats.maxDrawdownPct.toStringAsFixed(1)}%',
              valueColor: stats.maxDrawdownPct < 0
                  ? const Color(0xFF3D9E6B)
                  : const Color(0xFF9AA3B2),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Hero 卡片 ───────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double totalPnL;
  final int tradingDays;
  final int sellCount;
  final double winRate;
  const _HeroCard({
    required this.totalPnL,
    required this.tradingDays,
    required this.sellCount,
    required this.winRate,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final sign = totalPnL >= 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D5A8A), Color(0xFF4A6FA5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
          blurRadius: 16, offset: const Offset(0, 6),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '交易生涯總覽',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white60,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$sign${fmt.format(totalPnL.toInt())}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(children: [
            _HeroStat(label: '交易天數', value: '$tradingDays 天'),
            _HDivider(),
            _HeroStat(label: '總結清筆數', value: '$sellCount 筆'),
            _HDivider(),
            _HeroStat(label: '整體勝率', value: '${(winRate * 100).toStringAsFixed(1)}%'),
          ]),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
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

class _HDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 28, color: Colors.white24,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
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
      color: Color(0xFF1A1F2E),
    ),
  );
}

// ── 單筆紀錄 Tile ────────────────────────────────
class _HistTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final Color valueColor;
  final String? subtitle;

  const _HistTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.valueColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7ED)),
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
                    color: Color(0xFF9AA3B2),
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
                    fontSize: 10, color: Color(0xFF9AA3B2))),
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
        border: Border.all(color: const Color(0xFFE4E7ED)),
      ),
      child: Row(
        children: [
          Expanded(child: _Cell(cell: left, isLeft: true)),
          Container(width: 1, height: 56, color: const Color(0xFFE4E7ED)),
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
            color: Color(0xFF9AA3B2),
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
        style: const TextStyle(fontSize: 13, color: Color(0xFF9AA3B2)),
      ),
    ),
  );
}
