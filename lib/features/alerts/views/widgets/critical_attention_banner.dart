import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class CriticalAttentionBanner extends StatelessWidget {
  final int count;
  final String stationIdsText;
  final VoidCallback onTap;

  const CriticalAttentionBanner({
    super.key,
    required this.count,
    required this.stationIdsText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.criticalRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.criticalRed.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.criticalRed,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count need attention',
                    style: AppTypography.manropeSemiBold.copyWith(
                      fontSize: 14,
                      color: AppColors.criticalRed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$stationIdsText flagged high priority',
                    style: AppTypography.manropeRegular.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.criticalRed),
          ],
        ),
      ),
    );
  }
}
