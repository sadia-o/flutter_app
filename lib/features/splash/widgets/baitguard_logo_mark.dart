import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/baitguard_shield_mark.dart';

class BaitGaurdLogoMark extends StatelessWidget {
  const BaitGaurdLogoMark({
    super.key,
    this.size = 80.0, // Reasonably small size, roughly 75-80 foreground
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    // Total occupied width is larger because of the outer soft glows
    final totalSize = size * 1.5;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Large subtle dark-blue rounded-square glow layer
          Container(
            width: size * 1.3,
            height: size * 1.3,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(size * 0.4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // 2. Smaller darker/medium-blue rounded-square layer
          Container(
            width: size * 1.1,
            height: size * 1.1,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(size * 0.35),
            ),
          ),

          // 3. Compact bright-blue rounded-square foreground
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(size * 0.3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),

          // 4-7. Thin white outlined shield inside, nested contours, sensor
          BaitGuardShieldMark(size: size * 0.5, strokeColor: Colors.white),
        ],
      ),
    );
  }
}
