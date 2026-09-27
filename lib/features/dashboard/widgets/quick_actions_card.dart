import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';

class QuickActionsCard extends StatelessWidget {
  final DateTime lastUpdatedAt;
  final VoidCallback onRefresh;
  final VoidCallback onMap;
  final VoidCallback onReport;
  final VoidCallback onSettings;
  final bool isRefreshing;

  const QuickActionsCard({
    super.key,
    required this.lastUpdatedAt,
    required this.onRefresh,
    required this.onMap,
    required this.onReport,
    required this.onSettings,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Quick actions',
                style: AppTypography.manropeBold.copyWith(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Updated just now',
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionItem(
              icon: Icons.refresh,
              label: 'Refresh',
              onTap: isRefreshing ? null : onRefresh,
              showSpinner: isRefreshing,
            ),
            _QuickActionItem(
              icon: Icons.map_outlined,
              label: 'Map',
              onTap: onMap,
            ),
            _QuickActionItem(
              icon: Icons.insert_chart_outlined,
              label: 'Report',
              onTap: onReport,
            ),
            _QuickActionItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: onSettings,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showSpinner;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: showSpinner
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue,
                      ),
                    ),
                  )
                : Icon(icon, size: 24, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 11,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
