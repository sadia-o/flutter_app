import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../domain/models/station.dart';
import '../../../domain/models/station_status.dart';

/// Displays the "All stations (N)" card with a scrollable list of station rows.
class StationListCard extends StatelessWidget {
  final List<Station> stations;
  final void Function(String stationId) onStationTap;
  final VoidCallback onSeeAll;

  const StationListCard({
    super.key,
    required this.stations,
    required this.onStationTap,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.cardLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All stations (${stations.length})',
                  style: AppTypography.manropeBold.copyWith(
                    fontSize: 16,
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

          if (stations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  'No stations match your search or filter.',
                  textAlign: TextAlign.center,
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stations.length,
              separatorBuilder: (context, index) => Divider(
                color: AppColors.divider.withValues(alpha: 0.5),
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
              itemBuilder: (context, index) {
                return StationListRow(
                  station: stations[index],
                  onTap: onStationTap,
                );
              },
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// A single clickable station row.
class StationListRow extends StatelessWidget {
  final Station station;
  final void Function(String stationId) onTap;

  const StationListRow({super.key, required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dotColor = _statusColor(station);
    final baitColor = _baitColor(station.baitPercentage);

    return Semantics(
      button: true,
      label: '${station.id} ${station.locationDescription}',
      child: InkWell(
        onTap: () => onTap(station.id),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Location icon with status dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),

              // Station ID and location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.id,
                      style: AppTypography.manropeSemiBold.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.locationDescription,
                      style: AppTypography.manropeRegular.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Bait percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${station.baitPercentage.round()}%',
                    style: AppTypography.manropeBold.copyWith(
                      fontSize: 14,
                      color: baitColor,
                    ),
                  ),
                  Text(
                    'bait',
                    style: AppTypography.manropeRegular.copyWith(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(Station s) {
    if (s.isTampered || s.status == StationStatus.alert) {
      return AppColors.criticalRed;
    }
    switch (s.status) {
      case StationStatus.offline:
        return AppColors.textTertiary;
      case StationStatus.lowBait:
        return AppColors.warningAmber;
      case StationStatus.online:
        return AppColors.successGreen;
      case StationStatus.alert:
        return AppColors.criticalRed;
    }
  }

  Color _baitColor(double pct) {
    if (pct <= 25) return AppColors.criticalRed;
    if (pct <= 50) return AppColors.warningAmber;
    return AppColors.textPrimary;
  }
}
