import 'package:flutter/material.dart';
import '../../../domain/models/alert_status.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class AppStatusBadge extends StatelessWidget {
  final AlertStatus status;

  const AppStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case AlertStatus.open:
        backgroundColor = AppColors.criticalRed.withValues(alpha: 0.1);
        textColor = AppColors.criticalRed;
        text = 'Open';
        break;
      case AlertStatus.pending:
        backgroundColor = AppColors.warningAmber.withValues(alpha: 0.1);
        textColor = AppColors.warningAmber;
        text = 'Pending';
        break;
      case AlertStatus.inReview:
        backgroundColor = AppColors.primaryBlue.withValues(alpha: 0.1);
        textColor = AppColors.primaryBlue;
        text = 'In Review';
        break;
      case AlertStatus.resolved:
        backgroundColor = AppColors.successGreen.withValues(alpha: 0.1);
        textColor = AppColors.successGreen;
        text = 'Resolved';
        break;
      case AlertStatus.dismissed:
        backgroundColor = AppColors.borderSecondary;
        textColor = AppColors.textSecondary;
        text = 'Dismissed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 10,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
