import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        // Keep elements proportionally sized based on the container width.
        // The container will be constrained by the parent.

        return Stack(
          alignment: Alignment.center,
          children: [
            // Background Pale Oval
            Positioned(
              top: h * 0.2,
              child: Container(
                width: w * 0.8,
                height: w * 0.4,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(w * 0.4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.05),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

            // Connection paths (CustomPainter)
            Positioned.fill(
              child: CustomPaint(painter: _ConnectionPathPainter()),
            ),

            // Central Blue Device Graphic
            Positioned(
              top: h * 0.15,
              child: _CentralDevice(width: w * 0.35),
            ),

            // Left connected nodes
            Positioned(
              left: w * 0.15,
              top: h * 0.3,
              child: _ConnectedNode(
                color: AppColors.surface,
                iconColor: AppColors.primaryBlue,
                size: w * 0.12,
              ),
            ),
            Positioned(
              left: w * 0.2,
              top: h * 0.65,
              child: _ConnectedNode(
                color: AppColors.surface,
                iconColor: AppColors.successGreen,
                size: w * 0.1,
              ),
            ),

            // Right purple node
            Positioned(
              right: w * 0.18,
              top: h * 0.45,
              child: _ConnectedNode(
                color: AppColors.purple,
                iconColor: Colors.white,
                size: w * 0.14,
                glow: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CentralDevice extends StatelessWidget {
  final double width;

  const _CentralDevice({required this.width});

  @override
  Widget build(BuildContext context) {
    final double height = width * 1.6;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Main Body
          Positioned(
            top: width * 0.3,
            child: Container(
              width: width,
              height: height * 0.8,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(width * 0.3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Information bars
                  _InfoBar(width: width * 0.6),
                  const SizedBox(height: 8),
                  _InfoBar(width: width * 0.4),
                  const SizedBox(height: 8),
                  _InfoBar(width: width * 0.5),
                  const SizedBox(height: 24),
                  // Circular control
                  Container(
                    width: width * 0.25,
                    height: width * 0.25,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: width * 0.1,
                        height: width * 0.1,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // White Cap
          Positioned(
            top: 0,
            child: Container(
              width: width * 0.8,
              height: width * 0.45,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(width * 0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: width * 0.4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBar extends StatelessWidget {
  final double width;
  const _InfoBar({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _ConnectedNode extends StatelessWidget {
  final Color color;
  final Color iconColor;
  final double size;
  final bool glow;

  const _ConnectedNode({
    required this.color,
    required this.iconColor,
    required this.size,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow
                ? color.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: glow ? 15 : 10,
            spreadRadius: glow ? 2 : 0,
            offset: glow ? Offset.zero : const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.3,
          height: size * 0.3,
          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _ConnectionPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBlue = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintPurple = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double cx = size.width * 0.5;
    final double cy = size.height * 0.4;

    _drawDottedCurve(
      canvas,
      paintBlue,
      Offset(cx, cy),
      Offset(size.width * 0.2, size.height * 0.35),
      Offset(size.width * 0.35, size.height * 0.25),
    );

    _drawDottedCurve(
      canvas,
      paintBlue,
      Offset(cx, cy),
      Offset(size.width * 0.25, size.height * 0.68),
      Offset(size.width * 0.35, size.height * 0.6),
    );

    _drawDottedCurve(
      canvas,
      paintPurple,
      Offset(cx, cy),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width * 0.65, size.height * 0.35),
    );
  }

  void _drawDottedCurve(
    Canvas canvas,
    Paint paint,
    Offset p1,
    Offset p2,
    Offset controlPoint,
  ) {
    final Path path = Path();
    path.moveTo(p1.dx, p1.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, p2.dx, p2.dy);

    // simple manual dashing
    final PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double length = 6.0;
        final double gap = 6.0;
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + length),
          paint,
        );
        distance += length + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
