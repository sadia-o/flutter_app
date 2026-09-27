import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../domain/models/station.dart';
import '../../../domain/models/station_status.dart';
import '../../../domain/models/detection_event.dart';
import '../../../domain/models/detected_species.dart';
import '../view_models/station_detail_view_model.dart';
import 'package:intl/intl.dart';

class StationDetailScreen extends StatefulWidget {
  final String stationId;

  const StationDetailScreen({super.key, required this.stationId});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  late int _lastRefreshErrorId;
  late int _lastActionEventId;

  @override
  void initState() {
    super.initState();
    final vm = context.read<StationDetailViewModel>();
    _lastRefreshErrorId = vm.refreshErrorEventId;
    _lastActionEventId = vm.actionEventId;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StationDetailViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (vm.refreshErrorEventId != _lastRefreshErrorId) {
        _lastRefreshErrorId = vm.refreshErrorEventId;
        AppTopToast.show(context, vm.refreshErrorMessage ?? 'Refresh failed.');
      }
      if (vm.actionEventId != _lastActionEventId) {
        _lastActionEventId = vm.actionEventId;
        if (vm.actionErrorMessage != null) {
          AppTopToast.show(context, vm.actionErrorMessage!);
        } else if (vm.actionSuccessMessage != null) {
          AppTopToast.show(context, vm.actionSuccessMessage!);
        }
      }
    });

    if (vm.status == StationDetailLoadStatus.initial ||
        (vm.status == StationDetailLoadStatus.loading && vm.station == null)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const AppLoadingState(message: 'Loading station details…'),
      );
    }

    if (vm.status == StationDetailLoadStatus.error && vm.station == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: AppErrorState(
          message: 'Could not load station details.',
          onRetry: vm.load,
        ),
      );
    }

    final station = vm.station!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.refresh,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, station),
                const SizedBox(height: AppSpacing.lg),
                _buildCameraCard(station),
                const SizedBox(height: AppSpacing.lg),
                _buildMetricsRow(station, vm.events),
                const SizedBox(height: AppSpacing.lg),
                _buildEnvironmentCard(station),
                const SizedBox(height: AppSpacing.lg),
                _buildHistoryCard(context, vm.events),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Station station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                station.id,
                style: AppTypography.manropeBold.copyWith(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _buildStatusBadge(station),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 48), // Align with title
          child: Text(
            '${station.name} · ${station.locationDescription}',
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(Station station) {
    Color bgColor;
    Color textColor;
    String text;

    if (station.hasTamperData && station.isTampered) {
      bgColor = AppColors.redTint;
      textColor = AppColors.criticalRed;
      text = 'Tampered';
    } else if (station.status == StationStatus.offline) {
      bgColor = AppColors.divider;
      textColor = AppColors.textSecondary;
      text = 'Offline';
    } else if (station.status == StationStatus.alert) {
      bgColor = AppColors.amberTint;
      textColor = AppColors.warningAmber;
      text = 'Alert';
    } else {
      bgColor = AppColors.greenTint;
      textColor = AppColors.successGreen;
      text = 'Online';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text,
        style: AppTypography.manropeBold.copyWith(
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCameraCard(Station station) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark placeholder
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Stack(
        children: [
          // Simulated camera view icon in the center
          const Center(
            child: Icon(
              Icons.videocam_outlined,
              color: Colors.white24,
              size: 48,
            ),
          ),
          if (station.hasCamera)
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: station.isOnline
                            ? AppColors.warningAmber
                            : AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      station.isOnline ? 'CAMERA (PREVIEW)' : 'CAMERA OFFLINE',
                      style: AppTypography.manropeBold.copyWith(
                        fontSize: 10,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(
                'Static Preview Only',
                style: AppTypography.manropeMedium.copyWith(
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

  Widget _buildMetricsRow(Station station, List<DetectionEvent> events) {
    final recentDetections = events.where((e) {
      return DateTime.now().difference(e.timestamp).inDays <= 7;
    }).length;

    return Row(
      children: [
        Expanded(
          child: _buildCircularMetric(
            label: 'Bait',
            value: '${station.baitPercentage.round()}%',
            color: station.baitPercentage <= 25.0
                ? AppColors.criticalRed
                : AppColors.successGreen,
            progress: station.baitPercentage / 100,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildCircularMetric(
            label: 'Battery',
            value: '${station.batteryPercentage.round()}%',
            color: AppColors.primaryBlue,
            progress: station.batteryPercentage / 100,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildCircularMetric(
            label: 'Detections',
            value: '$recentDetections',
            color: AppColors.warningAmber,
            progress: 1.0, // Solid circle for count
          ),
        ),
      ],
    );
  }

  Widget _buildCircularMetric({
    required String label,
    required String value,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Text(
                    value,
                    style: AppTypography.manropeBold.copyWith(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard(Station station) {
    final formattedTime = DateFormat('MMM d, h:mm a').format(station.lastSeen);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environment',
            style: AppTypography.manropeBold.copyWith(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildEnvStat(
                Icons.thermostat_outlined,
                'Temperature',
                station.temperature != null ? '${station.temperature}°C' : '--',
              ),
              _buildEnvStat(
                Icons.water_drop_outlined,
                'Humidity',
                station.humidity != null ? '${station.humidity}%' : '--',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildEnvStat(Icons.access_time, 'Last Seen', formattedTime),
              _buildEnvStat(
                Icons.place_outlined,
                'Zone',
                station.locationDescription,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildEnvStat(
                Icons.security_outlined,
                'Tamper Sensor',
                station.hasTamperData
                    ? (station.isTampered ? 'Tampered' : 'Normal')
                    : 'Unavailable',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvStat(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.manropeSemiBold.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, List<DetectionEvent> events) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection History',
            style: AppTypography.manropeBold.copyWith(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'No recent detections',
                  style: AppTypography.manropeRegular.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (context, index) => const Divider(
                color: AppColors.borderSecondary,
                height: AppSpacing.xl,
              ),
              itemBuilder: (context, index) {
                return _buildEventRow(context, events[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventRow(BuildContext context, DetectionEvent event) {
    final title = _getEventTitle(event);
    final icon = _getEventIcon(event);
    final timeStr = DateFormat('MMM d, h:mm a').format(event.timestamp);

    return InkWell(
      onTap: () {
        if (event.alertId != null) {
          Navigator.of(
            context,
          ).pushNamed('/alert-detail', arguments: event.alertId);
        } else {
          AppTopToast.show(
            context,
            'This event does not have an associated alert.',
          );
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.manropeSemiBold.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildEventStatusBadge(event),
        ],
      ),
    );
  }

  String _getEventTitle(DetectionEvent event) {
    if (event.species == DetectedSpecies.rat) return 'Rat detected';
    if (event.species == DetectedSpecies.mouse) return 'Mouse detected';
    return 'Motion trigger';
  }

  IconData _getEventIcon(DetectionEvent event) {
    if (event.species == DetectedSpecies.rat ||
        event.species == DetectedSpecies.mouse) {
      return Icons.pest_control;
    }
    return Icons.motion_photos_on_outlined;
  }

  Widget _buildEventStatusBadge(DetectionEvent event) {
    Color bgColor;
    Color textColor;
    String text;

    switch (event.status) {
      case DetectionEventStatus.open:
        bgColor = AppColors.redTint;
        textColor = AppColors.criticalRed;
        text = 'Open';
        break;
      case DetectionEventStatus.pending:
        bgColor = AppColors.amberTint;
        textColor = AppColors.warningAmber;
        text = 'Pending';
        break;
      case DetectionEventStatus.resolved:
        bgColor = AppColors.greenTint;
        textColor = AppColors.successGreen;
        text = 'Resolved';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text,
        style: AppTypography.manropeBold.copyWith(
          fontSize: 11,
          color: textColor,
        ),
      ),
    );
  }
}
