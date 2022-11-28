import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DrawHorizontalLine extends CustomPainter {
  final Point<double> startPoint;
  final Point<double> finishPoint;
  DrawHorizontalLine(this.startPoint, this.finishPoint);

  final Paint _paint = Paint()
    ..color = Colors.black
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  @override
  void paint(Canvas canvas, Size size) {
    if (startPoint != finishPoint) {
      canvas.drawLine(Offset(startPoint.x, startPoint.y),
          Offset(finishPoint.x, finishPoint.y), _paint);
    } else {
      var path = Path();
      path.addOval(Rect.fromCircle(
        center: Offset(startPoint.x - 10, startPoint.y - 10),
        radius: 20.0,
      ));
      canvas.drawPath(path, _paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
