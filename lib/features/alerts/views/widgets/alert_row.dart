import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../domain/models/alert.dart';
import '../../../../domain/models/alert_type.dart';
import '../../../../domain/models/alert_status.dart';
import '../../../../domain/models/alert_severity.dart';

class AlertRow extends StatelessWidget {
  final Alert alert;
  final String stationLocation;
  final VoidCallback onTap;
  final VoidCallback? onResolve;
  final VoidCallback? onSnooze;

  const AlertRow({
    super.key,
    required this.alert,
    required this.stationLocation,
    required this.onTap,
    this.onResolve,
    this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: alert.isRead ? Colors.white : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.description,
                          style: AppTypography.manropeRegular.copyWith(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            fontWeight: alert.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${alert.stationId} · $stationLocation · ${_formatTime(alert.timestamp)}',
                          style: AppTypography.manropeRegular.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(),
                ],
              ),
              if (onResolve != null ||
                  onSnooze != null ||
                  alert.snoozedUntil != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (alert.snoozedUntil != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          'Snoozed until ${_formatTime(alert.snoozedUntil!)}',
                          style: AppTypography.manropeRegular.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else if (onSnooze != null)
                      TextButton(
                        onPressed: onSnooze,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('Snooze'),
                      ),
                    if (onResolve != null &&
                        alert.snoozedUntil == null &&
                        onSnooze != null)
                      const SizedBox(width: 8),
                    if (onResolve != null)
                      ElevatedButton.icon(
                        onPressed: onResolve,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primaryBlue
                              .withValues(alpha: 0.5),
                          disabledForegroundColor: Colors.white.withValues(
                            alpha: 0.8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Resolve',
                          style: AppTypography.manropeSemiBold.copyWith(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color color;

    switch (alert.type) {
      case AlertType.rodent:
        iconData = Icons.pest_control;
        color = AppColors.criticalRed;
        break;
      case AlertType.lowBait:
        iconData = Icons.battery_alert;
        color = AppColors.warningAmber;
        break;
      case AlertType.tamper:
        iconData = Icons.warning_amber_rounded;
        color = AppColors.criticalRed;
        break;
      case AlertType.stationOffline:
        iconData = Icons.wifi_off;
        color = AppColors.primaryBlue;
        break;
    }

    if (alert.severity == AlertSeverity.critical) {
      color = AppColors.criticalRed;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color bgColor;
    Color textColor;

    switch (alert.status) {
      case AlertStatus.open:
        text = 'Open';
        bgColor = AppColors.criticalRed.withValues(alpha: 0.1);
        textColor = AppColors.criticalRed;
        break;
      case AlertStatus.pending:
        text = 'Pending';
        bgColor = AppColors.warningAmber.withValues(alpha: 0.1);
        textColor = AppColors.warningAmber;
        break;
      case AlertStatus.inReview:
        text = 'In review';
        bgColor = AppColors.primaryBlue.withValues(alpha: 0.1);
        textColor = AppColors.primaryBlue;
        break;
      case AlertStatus.resolved:
        text = 'Resolved';
        bgColor = AppColors.successGreen.withValues(alpha: 0.1);
        textColor = AppColors.successGreen;
        break;
      case AlertStatus.dismissed:
        text = 'Dismissed';
        bgColor = AppColors.borderSecondary;
        textColor = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.manropeBold.copyWith(
          fontSize: 11,
          color: textColor,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // Show time e.g., 2:13 AM
      final hour = time.hour > 12
          ? time.hour - 12
          : (time.hour == 0 ? 12 : time.hour);
      final amPm = time.hour >= 12 ? 'PM' : 'AM';
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute $amPm';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
