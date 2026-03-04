//交易明細顯示元件
import 'package:flutter/material.dart';
import '../models/trade.dart';

class TradeTile extends StatefulWidget {
  final Trade trade;
  const TradeTile({
    super.key,
    required this.trade,
  });

  @override
  State<TradeTile> createState() => _TradeTileState();
}

class _TradeTileState extends State<TradeTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final trade = widget.trade;
    final isBuy = trade.type == TradeType.buy;
    final amountColor = trade.netAmount >= 0 ? Colors.red : Colors.green;

    return InkWell(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), //顏色轉變時間
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: isExpanded //邊框
                ? Border.all(color: Colors.blueGrey.shade200)
                : null,
            color: isExpanded
                ? Colors.blueGrey.shade50
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              Row(
                children: [ //左側：買/賣
                  Container( //左邊正方形
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isBuy ? Colors.blueGrey.shade200 : Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isBuy ? '買' : '賣',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded( //中間：交易資訊
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trade.name} (${trade.symbol})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${trade.date.year}/${trade.date.month}/${trade.date.day}'
                          '\n${trade.quantity} 股 @ ${trade.price}',
                          style: const TextStyle(fontSize: 12,color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Row( //右側
                    children: [
                      Text( //金額
                        trade.netAmount.toStringAsFixed(0),
                        style: TextStyle(color: amountColor,fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation( //翻轉箭頭
                        turns: isExpanded ? 0.5 : 0, //value*2*pi
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
              AnimatedCrossFade( //展開資訊
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              label: '價金',
                              value: trade.amount.toString(),
                            ),
                          ),
                          Expanded(
                            child: _InfoItem(
                              label: '手續費',
                              value: trade.fee.floor().toString(),
                            ),
                          ),
                          Expanded(
                            child: _InfoItem(
                              label: '交易稅',
                              value: trade.tax.floor().toString(),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _InfoItem(
                              label: '備註',
                              value: trade.note?.isNotEmpty == true ? trade.note! : '',
                            ),
                          ),
                          Expanded(
                            child: _InfoItem(
                              label: '策略標籤',
                              value: trade.tags.isNotEmpty ? trade.tags.join('、') : '_',
                            ),
                          )
                        ],
                      )
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}