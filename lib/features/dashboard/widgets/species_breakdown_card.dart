import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../domain/models/dashboard/dashboard_species.dart';
import '../../../domain/models/dashboard/species_breakdown_item.dart';

class SpeciesBreakdownCard extends StatelessWidget {
  final List<SpeciesBreakdownItem> breakdown;

  const SpeciesBreakdownCard({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    int totalCount = breakdown.fold(0, (sum, item) => sum + item.count);

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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Species breakdown',
              style: AppTypography.manropeBold.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                // Donut Chart
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          startDegreeOffset: -90,
                          sections: _buildSections(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            totalCount.toString(),
                            style: AppTypography.manropeExtraBold.copyWith(
                              fontSize: 24,
                              color: AppColors.textPrimary,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'TOTAL',
                            style: AppTypography.manropeBold.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                // Legend
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: breakdown.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getColor(item.species),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _getLabel(item.species),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.manropeSemiBold.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${item.percentage.toInt()}%',
                              style: AppTypography.manropeRegular.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return breakdown.map((item) {
      return PieChartSectionData(
        color: _getColor(item.species),
        value: item.percentage,
        title: '', // No titles on the segments themselves
        radius: 12, // Thickness of the donut
      );
    }).toList();
  }

  Color _getColor(DashboardSpecies species) {
    switch (species) {
      case DashboardSpecies.rat:
        return AppColors.criticalRed; // Rose
      case DashboardSpecies.mouse:
        return AppColors.warningAmber; // Amber
      case DashboardSpecies.other:
        return AppColors.textTertiary; // Gray
    }
  }

  String _getLabel(DashboardSpecies species) {
    switch (species) {
      case DashboardSpecies.rat:
        return 'Rat';
      case DashboardSpecies.mouse:
        return 'Mouse';
      case DashboardSpecies.other:
        return 'Other';
    }
  }
}
