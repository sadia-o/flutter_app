import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../domain/models/dashboard/dashboard_alert_item.dart';
import '../../../domain/models/alert_type.dart';

class DashboardAlertCard extends StatelessWidget {
  final List<DashboardAlertItem> alerts;
  final VoidCallback onSeeAll;
  final ValueChanged<String>? onAlertTap;
  final String title;
  final int? totalCount;

  const DashboardAlertCard({
    super.key,
    required this.alerts,
    required this.onSeeAll,
    this.onAlertTap,
    this.title = 'Recent alerts',
    this.totalCount,
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.manropeBold.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text(
                        totalCount != null
                            ? 'View All ($totalCount)'
                            : 'View All',
                        style: AppTypography.manropeSemiBold.copyWith(
                          fontSize: 12,
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
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...alerts.asMap().entries.map((entry) {
              final index = entry.key;
              final alert = entry.value;
              final isLast = index == alerts.length - 1;

              return Column(
                children: [
                  Semantics(
                    label: 'Alert: ${alert.title}, at ${alert.location}',
                    button: true,
                    container: true,
                    child: InkWell(
                      onTap: onAlertTap != null
                          ? () => onAlertTap!(alert.id)
                          : null,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.xs,
                        ),
                        child: _AlertRow(alert: alert),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: AppSpacing.xl,
                      color: AppColors.divider.withValues(alpha: 0.5),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final DashboardAlertItem alert;

  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getIconBackgroundColor(alert.type),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(
            _getIconData(alert.type),
            size: 20,
            color: _getIconColor(alert.type),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: AppTypography.manropeBold.copyWith(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${alert.location} · ${_formatTime(alert.timestamp)}',
                style: AppTypography.manropeRegular.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppStatusBadge(status: alert.status),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0 && now.day == time.day) {
      return DateFormat.jm().format(time); // "2:13 AM"
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != time.day)) {
      return 'Yesterday';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  IconData _getIconData(AlertType type) {
    switch (type) {
      case AlertType.rodent:
        return Icons.pest_control;
      case AlertType.tamper:
        return Icons.warning_amber_rounded;
      case AlertType.lowBait:
        return Icons.water_drop_outlined;
      case AlertType.stationOffline:
        return Icons.wifi_off;
    }
  }

  Color _getIconColor(AlertType type) {
    switch (type) {
      case AlertType.rodent:
      case AlertType.tamper:
        return AppColors.criticalRed;
      case AlertType.lowBait:
        return AppColors.warningAmber;
      case AlertType.stationOffline:
        return AppColors.textTertiary;
    }
  }

  Color _getIconBackgroundColor(AlertType type) {
    switch (type) {
      case AlertType.rodent:
      case AlertType.tamper:
        return AppColors.criticalRed.withValues(alpha: 0.1);
      case AlertType.lowBait:
        return AppColors.warningAmber.withValues(alpha: 0.1);
      case AlertType.stationOffline:
        return AppColors.divider;
    }
  }
}
