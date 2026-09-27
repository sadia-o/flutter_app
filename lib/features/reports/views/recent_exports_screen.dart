import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../domain/models/report_models.dart';
import '../view_models/reports_view_model.dart';

class RecentExportsScreen extends StatelessWidget {
  const RecentExportsScreen({super.key});

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsViewModel>(
      builder: (context, vm, child) {
        final exports = vm.dashboardData?.recentExports ?? [];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── Compact app bar matching Stations/Alerts style ──────────
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                forceElevated: true,
                leading: IconButton(
                  key: const Key('recent_exports_back'),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                titleSpacing: 0,
                title: Text(
                  'Recent Exports',
                  style: AppTypography.manropeSemiBold.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              if (exports.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No reports have been generated yet.'),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Container(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: exports.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: Colors.grey[100]),
                          itemBuilder: (context, index) {
                            return _ExportRow(
                              export: exports[index],
                              onDownload: vm.handleMockDownload,
                              onShare: vm.permissions.canShareMock
                                  ? vm.handleMockShare
                                  : null,
                              formatFileSize: _formatFileSize,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom safe space so content clears nav bar
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ExportRow extends StatelessWidget {
  final ReportExport export;
  final VoidCallback onDownload;
  final VoidCallback? onShare;
  final String Function(int) formatFileSize;

  const _ExportRow({
    required this.export,
    required this.onDownload,
    this.onShare,
    required this.formatFileSize,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = export.format == ReportFileFormat.pdf;
    final formatText = export.format.name.toUpperCase();
    final sizeText = formatFileSize(export.fileSizeBytes);
    final timeText = DateFormat(
      'MMM d, yyyy \u00B7 h:mm a',
    ).format(export.generatedAt);

    final iconColor = isPdf ? AppColors.primaryBlue : AppColors.successGreen;
    final iconBg = isPdf ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Colored icon container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPdf
                  ? Icons.insert_drive_file_outlined
                  : Icons.table_chart_outlined,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title + metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  export.title,
                  style: AppTypography.manropeSemiBold.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$formatText \u00B7 $sizeText',
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  timeText,
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action buttons
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            color: AppColors.textSecondary,
            iconSize: 20,
            onPressed: onDownload,
            tooltip: 'Download',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(8),
          ),
          if (onShare != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              color: AppColors.textSecondary,
              iconSize: 20,
              onPressed: onShare,
              tooltip: 'Share',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(8),
            ),
        ],
      ),
    );
  }
}
