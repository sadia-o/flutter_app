import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Navy Color
        Container(color: AppColors.splashBackground),

        // Central Top Blue Glow
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.3),
                radius: 0.8,
                colors: [
                  Color(0x330F6FFF), // Soft blue tint
                  Colors.transparent,
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),

        // Bottom Right Purple Glow
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.8, 0.8),
                radius: 0.7,
                colors: [
                  Color(0x227C3AED), // Soft purple tint
                  Colors.transparent,
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),

        // Faint Grid
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
          .withValues(alpha: 0.03) // Very faint white/blue-gray
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const double spacing = 40.0;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
