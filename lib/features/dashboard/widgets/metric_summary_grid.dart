import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import 'dashboard_metric_card.dart';

class MetricSummaryGrid extends StatelessWidget {
  final int totalStations;
  final int activeStations;
  final int refillNeeded;
  final int offlineStations;

  const MetricSummaryGrid({
    super.key,
    required this.totalStations,
    required this.activeStations,
    required this.refillNeeded,
    required this.offlineStations,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use 2 columns for phones, potentially more for wider screens
        final int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: constraints.maxWidth < 340 ? 1.2 : 1.5,
          children: [
            DashboardMetricCard(
              title: 'Total stations',
              value: totalStations.toString(),
              valueColor: AppColors.textPrimary,
              icon: Icons.place,
              iconColor: AppColors.textSecondary,
              iconBackgroundColor: AppColors.divider,
            ),
            DashboardMetricCard(
              title: 'Active now',
              value: activeStations.toString(),
              valueColor: AppColors.successGreen,
              icon: Icons.bolt,
              iconColor: AppColors.successGreen,
              iconBackgroundColor: AppColors.successGreen.withValues(
                alpha: 0.1,
              ),
            ),
            DashboardMetricCard(
              title: 'Need refill',
              value: refillNeeded.toString(),
              valueColor: AppColors.warningAmber,
              icon: Icons.water_drop,
              iconColor: AppColors.warningAmber,
              iconBackgroundColor: AppColors.warningAmber.withValues(
                alpha: 0.1,
              ),
            ),
            DashboardMetricCard(
              title: 'Offline',
              value: offlineStations.toString(),
              valueColor: AppColors.criticalRed,
              icon: Icons.wifi_off,
              iconColor: AppColors.criticalRed,
              iconBackgroundColor: AppColors.criticalRed.withValues(alpha: 0.1),
            ),
          ],
        );
      },
    );
  }
}
