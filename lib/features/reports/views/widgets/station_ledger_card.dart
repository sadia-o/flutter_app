import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../domain/models/report_models.dart';

class StationLedgerCard extends StatelessWidget {
  final List<StationReportLedgerEntry> entries;
  final void Function(String stationId)? onStationTap;

  const StationLedgerCard({
    super.key,
    required this.entries,
    this.onStationTap,
  });

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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Text(
              'Station ledger',
              style: AppTypography.manropeSemiBold.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: Text('No station data available.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length > 5 ? 5 : entries.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey[100]),
              itemBuilder: (context, index) {
                final displayEntries = entries.take(5).toList();
                final entry = displayEntries[index];

                final isHighUptime = (entry.uptimePercent ?? 100) >= 95;
                final uptimeColor = entry.uptimePercent == null
                    ? AppColors.textTertiary
                    : (isHighUptime
                          ? AppColors.successGreen
                          : AppColors.warningAmber);

                // Parse station code only (strip location from name if embedded)
                final stationCode = entry.stationCode
                    .split(' \u2014 ')[0]
                    .split(' - ')[0]
                    .trim();

                return InkWell(
                  onTap: onStationTap != null
                      ? () => onStationTap!(entry.stationId)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // Station code + location
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stationCode,
                                style: AppTypography.manropeSemiBold.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                entry.location,
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
                        // Detections + refills inline (Figma: "22 det  4 ref")
                        Expanded(
                          flex: 3,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${entry.detections} ',
                                      style: AppTypography.manropeSemiBold
                                          .copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.criticalRed,
                                          ),
                                    ),
                                    TextSpan(
                                      text: 'det',
                                      style: AppTypography.manropeRegular
                                          .copyWith(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${entry.baitRefills} ',
                                      style: AppTypography.manropeSemiBold
                                          .copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.purple,
                                          ),
                                    ),
                                    TextSpan(
                                      text: 'ref',
                                      style: AppTypography.manropeRegular
                                          .copyWith(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Uptime bar + %
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                entry.uptimePercent != null
                                    ? '${entry.uptimePercent!.toStringAsFixed(0)}%'
                                    : '—',
                                style: AppTypography.manropeSemiBold.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: uptimeColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              if (entry.uptimePercent != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: entry.uptimePercent! / 100,
                                    backgroundColor: Colors.grey[200],
                                    color: uptimeColor,
                                    minHeight: 4,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
