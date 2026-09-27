import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../domain/models/report_models.dart';
import '../../models/reports_permissions.dart';

class GenerateReportCard extends StatelessWidget {
  final ReportPeriod selectedPeriod;
  final bool isGenerating;
  final ReportTemplateType? generatingTemplateType;
  final Function(ReportTemplateType) onGenerate;
  final ReportsPermissions permissions;

  const GenerateReportCard({
    super.key,
    required this.selectedPeriod,
    required this.isGenerating,
    this.generatingTemplateType,
    required this.onGenerate,
    required this.permissions,
  });

  String _getDynamicSubtitle(ReportTemplateType type) {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthName = months[selectedPeriod.anchorDate.month - 1];
    final year = selectedPeriod.anchorDate.year;
    final quarter = ((selectedPeriod.anchorDate.month - 1) ~/ 3) + 1;

    if (type == ReportTemplateType.monthlyActivity) {
      switch (selectedPeriod.type) {
        case ReportPeriodType.week:
          return 'Past 7 days \u00B7 All stations';
        case ReportPeriodType.month:
          return '$monthName $year \u00B7 All stations';
        case ReportPeriodType.quarter:
          return 'Q$quarter $year \u00B7 All stations';
        case ReportPeriodType.year:
          return '${now.year} \u00B7 All stations';
      }
    } else if (type == ReportTemplateType.baitConsumption) {
      switch (selectedPeriod.type) {
        case ReportPeriodType.week:
          return 'Last 7 days';
        case ReportPeriodType.month:
          return 'Last 30 days';
        case ReportPeriodType.quarter:
          return 'Last 90 days';
        case ReportPeriodType.year:
          return 'Last 365 days';
      }
    } else {
      // complianceAudit
      switch (selectedPeriod.type) {
        case ReportPeriodType.week:
          return 'Week \u00B7 Audit trail';
        case ReportPeriodType.month:
          return '$monthName $year \u00B7 Audit trail';
        case ReportPeriodType.quarter:
          return 'Q$quarter $year \u00B7 Audit trail';
        case ReportPeriodType.year:
          return '${now.year} \u00B7 Audit trail';
      }
    }
  }

  // Per-template Figma icon and color
  IconData _iconFor(ReportTemplateType type) {
    switch (type) {
      case ReportTemplateType.monthlyActivity:
        return Icons.bar_chart_rounded;
      case ReportTemplateType.baitConsumption:
        return Icons.water_drop_outlined;
      case ReportTemplateType.complianceAudit:
        return Icons.verified_outlined;
    }
  }

  Color _iconColorFor(ReportTemplateType type) {
    switch (type) {
      case ReportTemplateType.monthlyActivity:
        return AppColors.primaryBlue;
      case ReportTemplateType.baitConsumption:
        return AppColors.successGreen;
      case ReportTemplateType.complianceAudit:
        return AppColors.purple;
    }
  }

  Color _iconBgFor(ReportTemplateType type) {
    switch (type) {
      case ReportTemplateType.monthlyActivity:
        return const Color(0xFFEFF6FF); // blue tint
      case ReportTemplateType.baitConsumption:
        return const Color(0xFFECFDF5); // green tint
      case ReportTemplateType.complianceAudit:
        return const Color(0xFFF5F3FF); // purple tint
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = [
      const ReportTemplate(
        type: ReportTemplateType.monthlyActivity,
        title: 'Monthly activity',
        subtitle: '',
        format: ReportFileFormat.pdf,
      ),
      const ReportTemplate(
        type: ReportTemplateType.baitConsumption,
        title: 'Bait consumption',
        subtitle: '',
        format: ReportFileFormat.csv,
      ),
      const ReportTemplate(
        type: ReportTemplateType.complianceAudit,
        title: 'Compliance audit',
        subtitle: '',
        format: ReportFileFormat.pdf,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Generate report',
              style: AppTypography.manropeSemiBold.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: templates.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (context, index) {
              final template = templates[index];
              final canGenerate = permissions.canGenerateTemplate(
                template.type,
              );
              final isThisGenerating = generatingTemplateType == template.type;
              final isDisabled = isGenerating || !canGenerate;

              final iconColor = canGenerate
                  ? _iconColorFor(template.type)
                  : AppColors.textTertiary;
              final iconBg = canGenerate
                  ? _iconBgFor(template.type)
                  : Colors.grey[100]!;

              // Action pill color — PDF: blue, CSV: green
              final isPdf = template.format == ReportFileFormat.pdf;
              final pillColor = canGenerate
                  ? (isPdf ? AppColors.primaryBlue : AppColors.successGreen)
                  : Colors.grey[400]!;
              final pillBg = canGenerate
                  ? (isPdf ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5))
                  : Colors.grey[100]!;
              final formatLabel = template.format.name.toUpperCase();

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Colored icon circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconFor(template.type),
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: AppTypography.manropeSemiBold.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: canGenerate
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _getDynamicSubtitle(template.type),
                            style: AppTypography.manropeRegular.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // PDF/CSV action pill (Figma style)
                    if (isThisGenerating)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: pillColor,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: isDisabled
                            ? null
                            : () => onGenerate(template.type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: pillBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                canGenerate
                                    ? Icons.file_download_outlined
                                    : Icons.lock_outline,
                                size: 13,
                                color: pillColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatLabel,
                                style: AppTypography.manropeSemiBold.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: pillColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
