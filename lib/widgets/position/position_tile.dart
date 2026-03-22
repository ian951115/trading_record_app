//庫存明細顯示元件
import 'package:flutter/material.dart';
import '../../models/position.dart';
import 'package:intl/intl.dart';

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
    final position = widget.position;
    final profitColor = position.unrealizedPnL >= 0 ? Colors.red : Colors.green;

    final formatter = NumberFormat('#,###');
    final pnl = position.unrealizedPnL;
    final formattedPnL = formatter.format(pnl.abs());
    final pnlText = pnl >= 0 ? '+$formattedPnL' : '-$formattedPnL';
    final pnlReturn = pnl >= 0
        ? '+${position.unrealizedReturn.toStringAsFixed(2)}%'
        : '-${position.unrealizedReturn.toStringAsFixed(2)}%';

    final priceFormatter = NumberFormat('#,###.##');

    return InkWell(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isExpanded
                ? Colors.blueGrey.shade50
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isExpanded
                ? Border.all(color: Colors.blueGrey.shade200)
                : null,
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
              Row( //第一行（永遠顯示）
                children: [
                  Expanded( //左側：名稱
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${position.name} (${position.symbol})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${position.quantity} 股  '
                          '均價 ${position.avgCost.toStringAsFixed(1)} '
                          '現價 ${priceFormatter.format(position.mockPrice)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row( //右側：未實現損益
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            pnlText,
                            style: TextStyle(
                              color: profitColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            pnlReturn,
                            style: TextStyle(
                              color: profitColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 100),
                        child: const Icon(
                          Icons.expand_more,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedCrossFade( //展開區（白色區塊）
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      Row( //第二排資訊
                        children: [
                          _InfoItem(
                            label: '市值',
                            value: formatter.format(position.marketValue),
                          ),
                          _InfoItem(
                            label: '成本',
                            value: formatter.format(position.totalCost),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox( //庫存明細按鈕
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            //之後做跳轉
                          },
                          child: const Text('股票明細'),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}