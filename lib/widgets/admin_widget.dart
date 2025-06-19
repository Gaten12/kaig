import 'package:flutter/material.dart';

class LineGraphPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double maxValue;
  final Color lineColor;

  LineGraphPainter(
      {required this.data, required this.maxValue, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 5.0
      ..style = PaintingStyle.fill;

    final path = Path();

    // Calculate scaling factors
    final double xStep = size.width / (data.length > 1 ? data.length - 1 : 1);
    final double yMax = size.height;

    // Draw lines and points
    for (int i = 0; i < data.length; i++) {
      final double x = i * xStep;
      final double y = yMax - (data[i].value / (maxValue > 0 ? maxValue : 1)) *
          yMax; // Avoid division by zero

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 3.0, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is LineGraphPainter &&
        (oldDelegate.data != data || oldDelegate.maxValue != maxValue ||
            oldDelegate.lineColor != lineColor);
  }
}