//庫存明細顯示元件
import 'package:flutter/material.dart';
import '../common/info_item.dart';
import '../../models/position.dart';
import '../../core/formatters.dart';
import '../../core/app_colors.dart';

class PositionTile extends StatefulWidget {
  final Position position;
  const PositionTile({
    super.key,
    required this.position,
  });

  @override
  State<PositionTile> createState() => _PositionTileState();
}

class _PositionTileState extends State<PositionTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.position;
    final pnlColor = p.unrealizedPnL >= 0
        ? Color(0xFFE8504A)
        : Color(0xFF3D9E6B);
    final pnlText = (p.unrealizedPnL >= 0 ? '+' : '') +
        AppFmt.num(p.unrealizedPnL);
    final retText = '${p.unrealizedReturn >= 0 ? '+' : ''}${p.unrealizedReturn.toStringAsFixed(2)}%';

    return GestureDetector(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded
              ? const Color(0xFFEBF0F8)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isExpanded
              ? const Color(0xFFC5D4EC)
              : const Color(0xFFE4E7ED),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── 主列 ────────────────
            Row(
              children: [
                Container( //左側:代碼徽章
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF0F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.symbol,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A6FA5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded( //中間：名稱+股數均價
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.quantity} 股 · 均 ${p.avgCost.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        p.livePrice != null
                            ? '現價 ${AppFmt.price(p.currentPrice)}'
                            : '現價載入中…',
                        style: TextStyle(
                          fontSize: 11,
                          color: p.livePrice != null
                              ? const Color(0xFF4A6FA5)
                              :  AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column( //右側：損益
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pnlText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: pnlColor,
                      ),
                    ),
                    Text(
                      retText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: pnlColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.expand_more,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),      
              ],
            ),
            // ── 展開區 ──────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InfoItem(
                            label: '市值',
                            value: AppFmt.num(p.marketValue),
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '成本',
                            value: AppFmt.num(p.totalCost),
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '持有天數',
                            value: '${p.holdingDays} 天',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InfoItem(
                            label: '股數',
                            value: '${p.quantity} 股',
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '均價',
                            value: p.avgCost.toStringAsFixed(1),
                          ),
                        ),
                        Expanded(
                          child: InfoItem(
                            label: '現價',
                            value: p.livePrice != null
                                ? AppFmt.price(p.currentPrice)
                                : '—',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 150),
            ),
          ],
        ),
      ),
    );
  }
}