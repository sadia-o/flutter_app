import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../models/alert_hotspot_station.dart';

class HotspotStationRow extends StatelessWidget {
  final AlertHotspotStation hotspot;
  final int maxCount;
  final VoidCallback onTap;

  const HotspotStationRow({
    super.key,
    required this.hotspot,
    required this.maxCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount == 0 ? 0.0 : hotspot.alertCount / maxCount;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${hotspot.stationId} · ${hotspot.location}',
                    style: AppTypography.manropeRegular.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${hotspot.alertCount} alerts',
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.borderSecondary,
              color: AppColors.criticalRed,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
