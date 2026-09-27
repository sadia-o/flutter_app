import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';

class CriticalAlertsSummaryCard extends StatelessWidget {
  final int criticalCount;
  final VoidCallback onViewAll;

  const CriticalAlertsSummaryCard({
    super.key,
    required this.criticalCount,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Critical Alerts. $criticalCount stations require immediate attention.',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.criticalRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.criticalRed.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.criticalRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Critical Alerts',
                          style: AppTypography.manropeBold.copyWith(
                            fontSize: 14,
                            color: AppColors.criticalRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$criticalCount stations require immediate attention',
                          style: AppTypography.manropeRegular.copyWith(
                            fontSize: 12,
                            color: AppColors.criticalRed.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: AppTypography.manropeSemiBold.copyWith(
                          fontSize: 12,
                          color: AppColors.criticalRed,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.criticalRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
