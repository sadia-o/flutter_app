import 'package:flutter/material.dart';

class BaitGuardShieldMark extends StatelessWidget {
  const BaitGuardShieldMark({
    super.key,
    required this.size,
    required this.strokeColor,
  });

  final double size;
  final Color strokeColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: BaitGuardShieldPainter(strokeColor: strokeColor),
      ),
    );
  }
}

class BaitGuardShieldPainter extends CustomPainter {
  BaitGuardShieldPainter({required this.strokeColor});

  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;

    // 4. Main thin white outlined shield
    final Path shieldPath = Path();
    shieldPath.moveTo(w * 0.5, 0);
    shieldPath.lineTo(w, h * 0.15);
    shieldPath.lineTo(w, h * 0.55);
    shieldPath.cubicTo(w, h * 0.8, w * 0.75, h * 0.95, w * 0.5, h);
    shieldPath.cubicTo(w * 0.25, h * 0.95, 0, h * 0.8, 0, h * 0.55);
    shieldPath.lineTo(0, h * 0.15);
    shieldPath.close();

    canvas.drawPath(shieldPath, paint);

    // 5. Nested contour/chevron lines near the upper shield
    final Path chevronPath = Path();
    chevronPath.moveTo(w * 0.2, h * 0.3);
    chevronPath.lineTo(w * 0.5, h * 0.45);
    chevronPath.lineTo(w * 0.8, h * 0.3);

    // Reduce stroke width for inner details
    paint.strokeWidth = 1.5;
    canvas.drawPath(chevronPath, paint);

    // 6. Small circular sensor/ring in the center of the shield
    final centerPoint = Offset(w * 0.5, h * 0.65);
    canvas.drawCircle(centerPoint, w * 0.15, paint);

    // 7. Small central dot
    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerPoint, w * 0.04, dotPaint);
  }

  @override
  bool shouldRepaint(covariant BaitGuardShieldPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor;
  }
}
