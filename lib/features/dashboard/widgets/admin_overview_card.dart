import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../domain/models/dashboard/dashboard_system_status.dart';

class AdminOverviewCard extends StatelessWidget {
  final int facilityCount;
  final int userCount;
  final int pendingRequestCount;
  final DashboardSystemStatus systemStatus;
  final VoidCallback onManageSystem;

  const AdminOverviewCard({
    super.key,
    required this.facilityCount,
    required this.userCount,
    required this.pendingRequestCount,
    required this.systemStatus,
    required this.onManageSystem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Admin Overview',
                  style: AppTypography.manropeBold.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(
                  Icons.admin_panel_settings,
                  size: 20,
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _OverviewTile(
                    title: 'Facilities',
                    value: facilityCount.toString(),
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _OverviewTile(
                    title: 'Users',
                    value: userCount.toString(),
                    color: AppColors.primaryBlue.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _OverviewTile(
                    title: 'Pending',
                    value: pendingRequestCount.toString(),
                    color: AppColors.warningAmber,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _OverviewTile(
                    title: 'System',
                    value: _getStatusString(systemStatus),
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
          InkWell(
            onTap: onManageSystem,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppRadii.lg),
              bottomRight: Radius.circular(AppRadii.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Manage System',
                    style: AppTypography.manropeSemiBold.copyWith(
                      fontSize: 13,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusString(DashboardSystemStatus status) {
    switch (status) {
      case DashboardSystemStatus.healthy:
        return 'Healthy';
      case DashboardSystemStatus.warning:
        return 'Warning';
      case DashboardSystemStatus.critical:
        return 'Critical';
    }
  }
}

class _OverviewTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _OverviewTile({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.manropeExtraBold.copyWith(
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
