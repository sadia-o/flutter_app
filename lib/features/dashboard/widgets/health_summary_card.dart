import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';

class HealthSummaryCard extends StatelessWidget {
  final int score;
  final int scoreChange;
  final String statusMessage;
  final int activeStations;
  final int totalStations;
  final int attentionStations;

  const HealthSummaryCard({
    super.key,
    required this.score,
    required this.scoreChange,
    required this.statusMessage,
    required this.activeStations,
    required this.totalStations,
    required this.attentionStations,
  });

  @override
  Widget build(BuildContext context) {
    final String sign = scoreChange > 0 ? '+' : '';
    final int clampedScore = score.clamp(0, 100);

    return Semantics(
      label:
          'System health score: $clampedScore. $statusMessage. $activeStations of $totalStations stations online, $attentionStations need attention. Score change this week: $sign$scoreChange points.',
      container: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0F172A), // Dark navy
              Color(0xFF0F2C3A), // Teal tint
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 280;

              final circleChart = SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _HealthScorePainter(score: clampedScore),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clampedScore.toString(),
                          style: AppTypography.manropeExtraBold.copyWith(
                            fontSize: 32,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'HEALTH',
                          style: AppTypography.manropeBold.copyWith(
                            fontSize: 8,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final textContent = Column(
                crossAxisAlignment: isNarrow
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            statusMessage,
                            style: AppTypography.manropeBold.copyWith(
                              fontSize: 10,
                              color: AppColors.successGreen,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '$activeStations of $totalStations stations online\n$attentionStations need attention',
                    style: AppTypography.manropeRegular.copyWith(
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$sign$scoreChange pts this week',
                    style: AppTypography.manropeBold.copyWith(
                      fontSize: 11,
                      color: AppColors.successGreen,
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    circleChart,
                    const SizedBox(height: AppSpacing.lg),
                    textContent,
                  ],
                );
              }

              return Row(
                children: [
                  circleChart,
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(child: textContent),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HealthScorePainter extends CustomPainter {
  final int score;

  _HealthScorePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 8.0;
    final double radius = (size.width - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint foregroundPaint = Paint()
      ..color =
          const Color(0xFF5EE9B5) // Health mint
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double startAngle = -pi / 2;
    // Score is safely pre-clamped before this is called
    final double sweepAngle = 2 * pi * (score / 100);

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HealthScorePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
