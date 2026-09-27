import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class FeatureChip extends StatelessWidget {
  final String label;

  const FeatureChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.blueSoftTint,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppTypography.manropeMedium.copyWith(
          color: AppColors.primaryBlue,
          fontSize: 13,
          fontWeight: FontWeight.w600, // SemiBold
        ),
      ),
    );
  }
}
