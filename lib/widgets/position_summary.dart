//庫存報酬率圓餅圖及資訊顯示元件
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PositionSummary extends StatelessWidget {
  final double totalCost;
  final double totalMarketValue;
  final double totalUnrealized;
  final double totalReturn;
  final double rotationTurns;
  final VoidCallback onRefresh;
  const PositionSummary({
    super.key,
    required this.totalCost,
    required this.totalMarketValue,
    required this.totalUnrealized,
    required this.totalReturn,
    required this.rotationTurns,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final profitColor = totalUnrealized >= 0 ? Colors.red :Colors.green;
    final double costValue = totalCost;
    final double profitValue = totalUnrealized.abs();

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12,vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox( //左邊Donut圖
                width: 140,
                height: 140,
                child: Stack( //堆疊
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0, //區間空隙大小，原2
                        centerSpaceRadius: 45, //中心圓半徑
                        sections: [
                          PieChartSectionData(
                            value: costValue, //把所有section總值加總並計算占比
                            color: Colors.blueGrey.shade300,
                            radius: 20, //外側圓半徑
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: profitValue,
                            color: profitColor,
                            radius: 20,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column( //中間報酬率
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '報酬率',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          '${totalReturn.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: profitColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded( //右邊資訊
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '總市值',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      formatter.format(totalMarketValue),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '總成本',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(formatter.format(totalCost)),
                    const SizedBox(height: 8),
                    const Text(
                      '報酬',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      totalUnrealized >= 0
                          ? '+${formatter.format(totalUnrealized)}'
                          : '-${formatter.format(totalUnrealized.abs())}',
                      style: TextStyle(
                        color: profitColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: 8,
          right: 16,
          child: GestureDetector(
            onTap: onRefresh,
            child: AnimatedRotation(
              turns: rotationTurns,
              duration: const Duration(milliseconds: 500),
              child: const Icon(Icons.refresh),
            ),
          ),
        ),
      ],
    );
  }
}