import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class DecorativeCircles extends StatelessWidget {
  const DecorativeCircles({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Small green circle on the upper-left side
            Positioned(
              left: w * 0.1,
              top: h * 0.15,
              child: _GlowingCircle(
                color: AppColors.successGreen,
                size: 16.0,
                glowOpacity: 0.4,
              ),
            ),

            // 2. Medium blue circle above and to the right of the logo
            Positioned(
              right: w * 0.2,
              top: h * 0.25,
              child: _GlowingCircle(
                color: AppColors.primaryBlue,
                size: 24.0,
                glowOpacity: 0.5,
              ),
            ),

            // 3. Large red circle on the lower-left side
            Positioned(
              left: w * 0.05,
              bottom: h * 0.2,
              child: _GlowingCircle(
                color: AppColors.alertRose, // or criticalRed
                size: 32.0,
                glowOpacity: 0.3,
              ),
            ),

            // 4. Medium purple circle to the right of the title/tagline region
            Positioned(
              right: w * 0.1,
              bottom: h * 0.4,
              child: _GlowingCircle(
                color: AppColors.purple,
                size: 20.0,
                glowOpacity: 0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowingCircle extends StatelessWidget {
  final Color color;
  final double size;
  final double glowOpacity;

  const _GlowingCircle({
    required this.color,
    required this.size,
    required this.glowOpacity,
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
            color: color.withValues(alpha: glowOpacity),
            blurRadius: size,
            spreadRadius: size * 0.5,
          ),
        ],
      ),
    );
  }
}
