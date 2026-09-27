import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';

class TodaysDetectionsCard extends StatelessWidget {
  final int detectionsToday;
  final double detectionsChangePercentage;

  const TodaysDetectionsCard({
    super.key,
    required this.detectionsToday,
    required this.detectionsChangePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = detectionsChangePercentage >= 0;
    final String sign = isPositive ? '+' : '';
    final Color trendColor = isPositive
        ? AppColors.successGreen
        : AppColors.criticalRed;
    final IconData trendIcon = isPositive
        ? Icons.trending_up
        : Icons.trending_down;

    return Semantics(
      label:
          'Today\'s Detections: $detectionsToday. $sign${detectionsChangePercentage.toStringAsFixed(0)}% from yesterday',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Detections',
                  style: AppTypography.manropeSemiBold.copyWith(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detectionsToday.toString(),
                  style: AppTypography.manropeExtraBold.copyWith(
                    fontSize: 32,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 16, color: trendColor),
                    const SizedBox(width: 4),
                    Text(
                      '$sign${detectionsChangePercentage.toStringAsFixed(0)}%',
                      style: AppTypography.manropeBold.copyWith(
                        fontSize: 18,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'from yesterday',
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
