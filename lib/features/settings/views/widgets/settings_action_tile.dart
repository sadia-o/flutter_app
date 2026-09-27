import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_radii.dart';

class SettingsActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? valueText;
  final IconData? leadingIcon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? trailingWidget;
  final VoidCallback onTap;
  final bool showChevron;
  final Color? destructiveColor;
  final bool isDestructive;

  const SettingsActionTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.valueText,
    this.leadingIcon,
    this.iconColor,
    this.iconBackgroundColor,
    this.trailingWidget,
    this.showChevron = true,
    this.destructiveColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  leadingIcon,
                  size: 20,
                  color: isDestructive
                      ? destructiveColor
                      : (iconColor ?? AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.manropeMedium.copyWith(
                      fontSize: 15,
                      color: isDestructive
                          ? (destructiveColor ?? AppColors.criticalRed)
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.manropeRegular.copyWith(
                        fontSize: 13,
                        color: isDestructive
                            ? (destructiveColor ?? AppColors.criticalRed)
                                  .withValues(alpha: 0.7)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailingWidget!,
            ] else if (valueText != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                valueText!,
                style: AppTypography.manropeMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
