import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_radii.dart';

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final double? changePercent;
  final bool positiveIsGood;

  /// Optional override for the value color (Figma uses distinct colors per KPI)
  final Color? valueColor;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.changePercent,
    this.positiveIsGood = true,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasChange = changePercent != null;
    final changeVal = changePercent ?? 0.0;
    final isPositive = changeVal > 0;
    final isNegative = changeVal < 0;
    final isZero = changeVal == 0;

    bool isGood;
    if (isZero) {
      isGood = true;
    } else if (positiveIsGood) {
      isGood = isPositive;
    } else {
      isGood = isNegative;
    }

    final changeColor = isGood ? AppColors.successGreen : AppColors.criticalRed;
    final arrowIcon = isPositive
        ? Icons.arrow_upward
        : (isNegative ? Icons.arrow_downward : Icons.remove);
    final prefix = isPositive ? '+' : '';
    final formattedChange = '$prefix${changeVal.toStringAsFixed(1)}%';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          if (hasChange) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(arrowIcon, size: 12, color: changeColor),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    formattedChange,
                    style: AppTypography.manropeRegular.copyWith(
                      fontSize: 12,
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
