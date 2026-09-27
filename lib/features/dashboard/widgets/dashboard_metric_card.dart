import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../domain/models/dashboard/dashboard_system_status.dart';

class DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String? helper;
  final DashboardSystemStatus? semanticStatus;

  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.helper,
    this.semanticStatus,
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.manropeExtraBold.copyWith(
                      fontSize: 28,
                      color: valueColor,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.manropeRegular.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (helper != null) ...[
                const SizedBox(height: 2),
                Text(
                  helper!,
                  style: AppTypography.manropeMedium.copyWith(
                    fontSize: 10,
                    color: _getSemanticColor(semanticStatus),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getSemanticColor(DashboardSystemStatus? status) {
    if (status == null) return AppColors.textTertiary;
    switch (status) {
      case DashboardSystemStatus.healthy:
        return AppColors.successGreen;
      case DashboardSystemStatus.warning:
        return AppColors.warningAmber;
      case DashboardSystemStatus.critical:
        return AppColors.criticalRed;
    }
  }
}
