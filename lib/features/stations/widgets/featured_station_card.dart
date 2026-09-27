import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../domain/models/detected_species.dart';
import '../../../domain/models/station_overview_data.dart';
import '../../../domain/models/station_status.dart';
import '../models/station_permissions.dart';

class FeaturedStationCard extends StatelessWidget {
  final StationOverviewData overview;
  final StationPermissions permissions;
  final bool isRefilling;
  final bool isSilencing;

  final void Function(String stationId) onStationTap;
  final void Function(String stationId) onCameraTap;
  final void Function(String stationId) onViewHistory;
  final void Function(String stationId) onLocate;
  final void Function(String stationId) onRefill;
  final void Function(String stationId) onSilence;

  const FeaturedStationCard({
    super.key,
    required this.overview,
    required this.permissions,
    required this.isRefilling,
    required this.isSilencing,
    required this.onStationTap,
    required this.onCameraTap,
    required this.onViewHistory,
    required this.onLocate,
    required this.onRefill,
    required this.onSilence,
  });

  @override
  Widget build(BuildContext context) {
    final station = overview.station;
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
          // ── Header ──────────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => onStationTap(station.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    station.id,
                    style: AppTypography.manropeExtraBold.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      station.locationDescription,
                      style: AppTypography.manropeRegular.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StationStatusBadge(
                    status: station.status,
                    isTampered: station.isTampered,
                  ),
                ],
              ),
            ),
          ),

          // ── Camera / Night-vision preview ────────────────────────────────
          GestureDetector(
            onTap: () => onCameraTap(station.id),
            child: _CameraPreview(
              hasCamera: station.hasCamera,
              temperature: station.temperature,
              humidity: station.humidity,
              recentSpecies: overview.recentSpecies,
              recentConfidence: overview.recentConfidence,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Metrics ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _MetricColumn(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: _baitColor(station.baitPercentage),
                  value: '${station.baitPercentage.round()}%',
                  valueColor: _baitColor(station.baitPercentage),
                  label: 'Bait',
                  progress: station.baitPercentage / 100.0,
                  progressColor: _baitColor(station.baitPercentage),
                ),
                _verticalDivider(),
                _MetricColumn(
                  icon: Icons.battery_charging_full_outlined,
                  iconColor: _batteryColor(station.batteryPercentage),
                  value: '${station.batteryPercentage.round()}%',
                  valueColor: _batteryColor(station.batteryPercentage),
                  label: 'Battery',
                  progress: station.batteryPercentage / 100.0,
                  progressColor: _batteryColor(station.batteryPercentage),
                ),
                _verticalDivider(),
                _MetricColumn(
                  icon: Icons.bolt_outlined,
                  iconColor: AppColors.primaryBlue,
                  value: '${overview.detectionCount}',
                  valueColor: AppColors.primaryBlue,
                  label: 'Detects',
                  progress: null,
                  progressColor: AppColors.primaryBlue,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(
            color: AppColors.divider.withValues(alpha: 0.6),
            height: 1,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── 7-day activity ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '7-day activity',
                  style: AppTypography.manropeSemiBold.copyWith(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => onViewHistory(station.id),
                  child: Text(
                    'View history',
                    style: AppTypography.manropeSemiBold.copyWith(
                      fontSize: 13,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _ActivitySparkline(points: overview.sevenDayActivity),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Action buttons ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                if (permissions.canRefill)
                  Expanded(
                    child: _ActionButton(
                      label: 'Refill',
                      icon: Icons.refresh,
                      isPrimary: true,
                      isLoading: isRefilling,
                      onTap: isRefilling ? null : () => onRefill(station.id),
                    ),
                  ),
                if (permissions.canRefill && permissions.canSilence)
                  const SizedBox(width: AppSpacing.sm),
                if (permissions.canSilence)
                  Expanded(
                    child: _ActionButton(
                      label: station.notificationsMuted
                          ? 'Unsilence'
                          : 'Silence',
                      icon: station.notificationsMuted
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      isPrimary: false,
                      isLoading: isSilencing,
                      onTap: isSilencing ? null : () => onSilence(station.id),
                    ),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ActionButton(
                    label: 'Locate',
                    icon: Icons.near_me_outlined,
                    isPrimary: false,
                    isLoading: false,
                    onTap: () => onLocate(station.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
    width: 1,
    height: 60,
    color: AppColors.divider.withValues(alpha: 0.6),
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  );

  Color _baitColor(double pct) {
    if (pct <= 25) return AppColors.criticalRed;
    if (pct <= 50) return AppColors.warningAmber;
    return AppColors.successGreen;
  }

  Color _batteryColor(double pct) {
    if (pct <= 20) return AppColors.criticalRed;
    if (pct <= 50) return AppColors.warningAmber;
    return AppColors.successGreen;
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StationStatusBadge extends StatelessWidget {
  final StationStatus status;
  final bool isTampered;

  const _StationStatusBadge({required this.status, required this.isTampered});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _resolve() {
    if (isTampered) return ('Tamper', AppColors.criticalRed);
    switch (status) {
      case StationStatus.alert:
        return ('Alert', AppColors.criticalRed);
      case StationStatus.offline:
        return ('Offline', AppColors.textTertiary);
      case StationStatus.lowBait:
        return ('Low bait', AppColors.warningAmber);
      case StationStatus.online:
        return ('Online', AppColors.successGreen);
    }
  }
}

// ── Camera preview ────────────────────────────────────────────────────────────

class _CameraPreview extends StatelessWidget {
  final bool hasCamera;
  final double? temperature;
  final double? humidity;
  final DetectedSpecies? recentSpecies;
  final double? recentConfidence;

  const _CameraPreview({
    required this.hasCamera,
    required this.temperature,
    required this.humidity,
    required this.recentSpecies,
    required this.recentConfidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Stack(
        children: [
          // Camera icon and label
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_outlined,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 36,
                ),
                const SizedBox(height: 6),
                Text(
                  'Night vision feed',
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),

          // LIVE badge (top left)
          if (hasCamera)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.criticalRed,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: AppTypography.manropeBold.copyWith(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Temp / humidity (bottom left)
          if (temperature != null && humidity != null)
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  '${temperature!.toStringAsFixed(0)}°C · ${humidity!.toStringAsFixed(0)}% RH',
                  style: AppTypography.jetbrainsMonoRegular.copyWith(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Species / confidence badge (bottom right)
          if (recentSpecies != null && recentSpecies != DetectedSpecies.none)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.criticalRed.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  '▲ ${_speciesLabel(recentSpecies!)} · ${((recentConfidence ?? 0) * 100).round()}%',
                  style: AppTypography.manropeSemiBold.copyWith(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _speciesLabel(DetectedSpecies s) {
    switch (s) {
      case DetectedSpecies.rat:
        return 'Rat';
      case DetectedSpecies.mouse:
        return 'Mouse';
      case DetectedSpecies.none:
        return 'Unknown';
    }
  }
}

// ── Metric column ─────────────────────────────────────────────────────────────

class _MetricColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;
  final double? progress;
  final Color progressColor;

  const _MetricColumn({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.jetbrainsMonoBold.copyWith(
              fontSize: 22,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress!.clamp(0.0, 1.0),
              backgroundColor: progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 3,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Activity sparkline ────────────────────────────────────────────────────────

class _ActivitySparkline extends StatelessWidget {
  final List<dynamic> points; // StationActivityPoint

  const _ActivitySparkline({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), (points[i].detections as int).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryBlue,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? AppColors.primaryBlue : Colors.white;
    final fgColor = isPrimary ? Colors.white : AppColors.textPrimary;
    final borderColor = isPrimary ? Colors.transparent : AppColors.divider;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: borderColor),
        ),
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: fgColor),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTypography.manropeSemiBold.copyWith(
                      fontSize: 13,
                      color: fgColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
