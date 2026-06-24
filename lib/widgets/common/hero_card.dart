//藍漸層摘要卡片
import 'package:flutter/material.dart';

// ── Hero卡片白色垂直分隔線 ────────────────────────────────────────
class HeroDivider extends StatelessWidget {
  final double horizontalMargin;
  const HeroDivider({super.key, this.horizontalMargin = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 32,
      color: Colors.white24,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
    );
  }
}

// ── 下方格子統計資料 ───────────────────────────────────────────
class HeroStat {
  final String label;
  final String value;
  final Color valueColor;
 
  const HeroStat({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });
}

// ── HeroCard ───────────────────────────────────────────
class HeroCard extends StatelessWidget {
  final String title;
  //主數值（大字），由呼叫方自行組Text widget以保持彈性
  final Widget mainValue;
  //下方格子，2或3格皆可
  final List<HeroStat> stats;
  //右上角額外元件（例如眼睛按鈕），可省略
  final Widget? trailing;
  //自訂漸層色；不傳則使用預設藍色
  final List<Color>? colors;

  static const _defaultColors = [
    Color(0xFF3D5A8A),
    Color(0xFF4A6FA5),
    Color(0xFF5E85BE),
  ];

  const HeroCard({
    super.key,
    required this.title,
    required this.mainValue,
    required this.stats,
    this.trailing,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final gradColors = colors ?? _defaultColors;
    final shadowColor = gradColors[gradColors.length > 1 ? 1 : 0];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: shadowColor.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row( //標題列
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 4),

          mainValue, //主數值

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),

          Row( //下方格子
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                if (i > 0) const HeroDivider(horizontalMargin: 12),
                Expanded(child: _HeroStatCell(stat: stats[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatCell extends StatelessWidget {
  final HeroStat stat;
  const _HeroStatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.label,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
        const SizedBox(height: 3),
        Text(
          stat.value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: stat.valueColor,
          ),
        ),
      ],
    );
  }
}