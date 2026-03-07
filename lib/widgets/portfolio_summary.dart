//主畫面總資產概覽
import 'package:flutter/material.dart';
import 'package:trading_record_app/models/position.dart';

class PortfolioSummary extends StatelessWidget {
  final double cash;
  final double marketValue;
  final double totalAsset;
  final bool isObscured;
  final VoidCallback onToggleObscure;

  const PortfolioSummary({
    super.key,
    required this.cash,
    required this.marketValue,
    required this.totalAsset,
    required this.isObscured,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('現金: ${isObscured ? '****' : cash.toStringAsFixed(2)}'),
                Text('市值: ${isObscured ? '****' : marketValue.toStringAsFixed(2)}'),
                Text('總資產: ${isObscured ? '****' : totalAsset.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 16,
          child: IconButton(
            icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggleObscure,
          ),
        ),
      ],
    );
  }
}