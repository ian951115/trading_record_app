//迷你趨勢線顯示元件
import 'package:flutter/material.dart';

class MiniSparkline extends StatelessWidget {
  final List<double> data;

  const MiniSparkline({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox();
    }

    return CustomPaint(
      painter: _SparklinePainter(data),
      size: const Size(double.infinity, 30),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;

  _SparklinePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs() < 1e-6 ? 1 : maxVal -minVal;

    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}