import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../domain/models/report_models.dart';

class ReportsDetectionTrendChart extends StatelessWidget {
  final List<ReportTrendPoint> trend;
  final ReportPeriodType periodType;

  const ReportsDetectionTrendChart({
    super.key,
    required this.trend,
    required this.periodType,
  });

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final double maxY =
        trend.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY / 4) == 0 ? 1 : maxY / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[200], strokeWidth: 1);
            },
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
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trend.length) {
                    return const SizedBox.shrink();
                  }
                  // For month or longer, show fewer labels to avoid crowding
                  if (trend.length > 7 &&
                      index % (trend.length ~/ 5) != 0 &&
                      index != trend.length - 1) {
                    return const SizedBox.shrink();
                  }

                  final point = trend[index];
                  String text;
                  if (periodType == ReportPeriodType.week) {
                    text = DateFormat('E').format(point.date); // Mon, Tue
                  } else if (periodType == ReportPeriodType.year) {
                    text = DateFormat('MMM').format(point.date); // Jan, Feb
                  } else {
                    text = DateFormat('MM/dd').format(point.date);
                  }

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      text,
                      style: AppTypography.manropeRegular
                          .copyWith(fontSize: 12)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: AppTypography.manropeRegular
                        .copyWith(fontSize: 12)
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (trend.length - 1).toDouble(),
          minY: 0,
          maxY: maxY == 0 ? 10 : maxY,
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.value);
              }).toList(),
              isCurved: true,
              color: AppColors.purple,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.purple.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
