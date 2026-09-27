import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';

class AdminQuickActionsCard extends StatelessWidget {
  final DateTime lastUpdatedAt;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onMap;
  final VoidCallback onReports;
  final VoidCallback onUsers;
  final VoidCallback onSettings;

  const AdminQuickActionsCard({
    super.key,
    required this.lastUpdatedAt,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onMap,
    required this.onReports,
    required this.onUsers,
    required this.onSettings,
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: AppTypography.manropeBold.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Updated ${_formatTime(lastUpdatedAt)}',
                style: AppTypography.manropeRegular.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ActionItem(
                  icon: isRefreshing ? null : Icons.refresh,
                  isRefreshing: isRefreshing,
                  label: 'Refresh',
                  onTap: isRefreshing ? () {} : onRefresh,
                ),
              ),
              Expanded(
                child: _ActionItem(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  onTap: onMap,
                ),
              ),
              Expanded(
                child: _ActionItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Reports',
                  onTap: onReports,
                ),
              ),
              Expanded(
                child: _ActionItem(
                  icon: Icons.people_outline,
                  label: 'Users',
                  onTap: onUsers,
                ),
              ),
              Expanded(
                child: _ActionItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: onSettings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time); // "2:13 PM"
  }
}

class _ActionItem extends StatelessWidget {
  final IconData? icon;
  final bool isRefreshing;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    this.icon,
    this.isRefreshing = false,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isRefreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : Icon(icon, color: AppColors.primaryBlue, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 11,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
