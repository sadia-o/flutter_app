import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../domain/models/dashboard/activity_data_point.dart';

class ActivityChartCard extends StatelessWidget {
  final List<ActivityDataPoint> series;
  final int detectionsToday;
  final double activityChangePercentage;

  const ActivityChartCard({
    super.key,
    required this.series,
    required this.detectionsToday,
    required this.activityChangePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final String sign = activityChangePercentage > 0 ? '+' : '';

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity today',
                        style: AppTypography.manropeBold.copyWith(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            activityChangePercentage > 0
                                ? Icons.arrow_outward
                                : Icons.arrow_downward,
                            size: 14,
                            color: activityChangePercentage > 0
                                ? AppColors.successGreen
                                : AppColors.criticalRed,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$sign${activityChangePercentage.toInt()}% vs yesterday',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.manropeRegular.copyWith(
                                fontSize: 11,
                                color: activityChangePercentage > 0
                                    ? AppColors.successGreen
                                    : AppColors.criticalRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      detectionsToday.toString(),
                      style: AppTypography.manropeExtraBold.copyWith(
                        fontSize: 24,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'detections',
                      style: AppTypography.manropeRegular.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 140,
              width: double.infinity,
              child: series.isEmpty
                  ? const Center(child: Text('No data'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 10,
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 3,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 6.0,
                                  child: Text(
                                    '${value.toInt()}h',
                                    style: AppTypography.manropeSemiBold
                                        .copyWith(
                                          color: AppColors.textTertiary,
                                          fontSize: 10,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 24,
                        minY: 0,
                        maxY: 50, // Roughly scaled for the peak of 45
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generateSpots(),
                            isCurved: true,
                            color: AppColors.primaryBlue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue.withValues(alpha: 0.2),
                                  AppColors.primaryBlue.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: AppColors.primaryBlue,
                            tooltipRoundedRadius: AppRadii.md,
                            tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            tooltipMargin: 16,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  '${spot.y.toInt()} detections\n',
                                  AppTypography.manropeBold.copyWith(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${spot.x.toInt()}h',
                                      style: AppTypography.manropeRegular
                                          .copyWith(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                );
                              }).toList();
                            },
                          ),
                          getTouchedSpotIndicator: (barData, spotIndexes) {
                            return spotIndexes.map((spotIndex) {
                              return TouchedSpotIndicatorData(
                                const FlLine(
                                  color: AppColors.primaryBlue,
                                  strokeWidth: 2,
                                  dashArray: [4, 4],
                                ),
                                FlDotData(
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 4,
                                          color: Colors.white,
                                          strokeWidth: 2,
                                          strokeColor: AppColors.primaryBlue,
                                        );
                                      },
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    // Map the 8 points representing the 24 hours back into X values (0-24)
    // Assuming series represents the last 24 hours in chronological order
    if (series.isEmpty) return [];

    // We expect 8 points representing 3h, 6h, ..., 24h ago
    // Or we map them equally across the X axis.
    List<FlSpot> spots = [];
    double interval = 24 / (series.length > 1 ? series.length - 1 : 1);

    for (int i = 0; i < series.length; i++) {
      spots.add(FlSpot(i * interval, series[i].count.toDouble()));
    }

    return spots;
  }
}
