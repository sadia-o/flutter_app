import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../domain/models/report_models.dart';

class RecentExportsCard extends StatelessWidget {
  final List<ReportExport> exports;
  final VoidCallback onSeeAll;
  final VoidCallback onDownloadMock;

  const RecentExportsCard({
    super.key,
    required this.exports,
    required this.onSeeAll,
    required this.onDownloadMock,
  });

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays == 0) {
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Header row: "Recent exports"  |  "See all >"
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent exports',
                  style: AppTypography.manropeSemiBold.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Row(
                    children: [
                      Text(
                        'See all',
                        style: AppTypography.manropeSemiBold.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
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
          ),
          Divider(height: 1, color: Colors.grey[200]),
          if (exports.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: Text('No reports have been generated yet.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exports.length > 3 ? 3 : exports.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey[100]),
              itemBuilder: (context, index) {
                final export = exports[index];
                final formatText = export.format.name.toUpperCase();
                final sizeText = _formatFileSize(export.fileSizeBytes);
                final timeText = _formatRelativeTime(export.generatedAt);

                // Figma uses a document icon in a pale blue or grey tint box
                final isPdf = export.format == ReportFileFormat.pdf;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPdf
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPdf
                              ? Icons.insert_drive_file_outlined
                              : Icons.table_chart_outlined,
                          color: isPdf
                              ? AppColors.primaryBlue
                              : AppColors.successGreen,
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
                            const SizedBox(height: 1),
                            Text(
                              '$formatText \u00B7 $sizeText \u00B7 $timeText',
                              style: AppTypography.manropeRegular.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Download icon button
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined),
                        color: AppColors.textSecondary,
                        iconSize: 20,
                        onPressed: onDownloadMock,
                        tooltip: 'Download',
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: const EdgeInsets.all(8),
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
