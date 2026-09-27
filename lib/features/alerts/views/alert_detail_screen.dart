import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../domain/models/alert.dart';
import '../../../domain/models/alert_type.dart';
import '../../../domain/models/alert_status.dart';
import '../../../domain/models/alert_severity.dart';
import '../../../domain/models/detection_event.dart';
import '../view_models/alert_detail_view_model.dart';
import '../../../core/widgets/app_top_toast.dart';

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({super.key});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  int _lastRefreshErrorEventId = 0;
  int _lastActionSuccessEventId = 0;
  int _lastActionErrorEventId = 0;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AlertDetailViewModel>().addListener(_onViewModelChange);
      }
    });
  }

  void _onViewModelChange() {
    if (!mounted) return;
    final vm = context.read<AlertDetailViewModel>();

    if (vm.refreshErrorEventId > _lastRefreshErrorEventId) {
      _lastRefreshErrorEventId = vm.refreshErrorEventId;
      if (vm.refreshErrorMessage != null) {
        _showToast(vm.refreshErrorMessage!, isError: true);
      }
    }

    if (vm.actionErrorEventId > _lastActionErrorEventId) {
      _lastActionErrorEventId = vm.actionErrorEventId;
      if (vm.actionErrorMessage != null) {
        _showToast(vm.actionErrorMessage!, isError: true);
      }
    }

    if (vm.actionSuccessEventId > _lastActionSuccessEventId) {
      _lastActionSuccessEventId = vm.actionSuccessEventId;
      if (vm.actionSuccessMessage != null) {
        _showToast(vm.actionSuccessMessage!, isError: false);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    AppTopToast.show(context, message);
  }

  Future<void> _confirmResolve(AlertDetailViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Alert'),
        content: Text('Are you sure you want to resolve alert ${vm.alertId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      vm.resolveAlert();
    }
  }

  Future<void> _confirmDismiss(AlertDetailViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dismiss Alert'),
        content: Text('Are you sure you want to dismiss alert ${vm.alertId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.criticalRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      vm.dismissAlert();
    }
  }

  Future<void> _confirmSnooze(AlertDetailViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Snooze Alert'),
        content: Text('Snooze alert ${vm.alertId} for 1 hour?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Snooze'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      vm.snoozeAlert(DateTime.now().add(const Duration(hours: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlertDetailViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (vm.error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                vm.error!,
                style: AppTypography.manropeRegular.copyWith(
                  fontSize: 14,
                  color: AppColors.criticalRed,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<AlertDetailViewModel>().refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final alert = vm.alert;
    final station = vm.station;

    if (alert == null || station == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Alert not found.')),
      );
    }

    final isResolved = alert.status == AlertStatus.resolved;
    final isDismissed = alert.status == AlertStatus.dismissed;
    final isActionable = !isResolved && !isDismissed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isPopping) return;
        _isPopping = true;
        final latestAlert = context
            .read<AlertDetailViewModel>()
            .lastUpdatedAlert;
        Navigator.of(context).pop(latestAlert);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackButton(context),
                    const SizedBox(height: 24),
                    Text(
                      'Alert Detail',
                      style: AppTypography.manropeBold.copyWith(
                        fontSize: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSummaryCard(alert, station.locationDescription),
                    const SizedBox(height: 24),
                    _buildInformationCard(
                      alert,
                      station.name,
                      station.locationDescription,
                    ),
                    if (vm.hasEvidence) ...[
                      const SizedBox(height: 24),
                      _buildEvidenceCard(vm.linkedEvidenceEvent!),
                    ],
                    const SizedBox(height: 32),
                    if (isActionable) _buildActionArea(context, vm),
                    if (vm.permissions?.canViewStation == true) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/station-detail',
                              arguments: station.id,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: AppColors.borderSecondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('View Station'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return InkWell(
      onTap: () {
        if (_isPopping) return;
        _isPopping = true;
        final latestAlert = context
            .read<AlertDetailViewModel>()
            .lastUpdatedAlert;
        Navigator.of(context).pop(latestAlert);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Alert alert, String location) {
    IconData iconData = Icons.info_outline;
    Color color = AppColors.primaryBlue;

    switch (alert.type) {
      case AlertType.rodent:
        iconData = Icons.pest_control;
        color = AppColors.criticalRed;
        break;
      case AlertType.lowBait:
        iconData = Icons.battery_alert;
        color = AppColors.warningAmber;
        break;
      case AlertType.tamper:
        iconData = Icons.warning_amber_rounded;
        color = AppColors.criticalRed;
        break;
      case AlertType.stationOffline:
        iconData = Icons.wifi_off;
        color = AppColors.primaryBlue;
        break;
    }

    if (alert.severity == AlertSeverity.critical) {
      color = AppColors.criticalRed;
    }

    String statusText = '';
    Color statusBgColor = Colors.transparent;
    Color statusTextColor = Colors.black;

    switch (alert.status) {
      case AlertStatus.open:
        statusText = 'Open';
        statusBgColor = AppColors.criticalRed.withValues(alpha: 0.1);
        statusTextColor = AppColors.criticalRed;
        break;
      case AlertStatus.pending:
        statusText = 'Pending';
        statusBgColor = AppColors.warningAmber.withValues(alpha: 0.1);
        statusTextColor = AppColors.warningAmber;
        break;
      case AlertStatus.inReview:
        statusText = 'In review';
        statusBgColor = AppColors.primaryBlue.withValues(alpha: 0.1);
        statusTextColor = AppColors.primaryBlue;
        break;
      case AlertStatus.resolved:
        statusText = 'Resolved';
        statusBgColor = AppColors.successGreen.withValues(alpha: 0.1);
        statusTextColor = AppColors.successGreen;
        break;
      case AlertStatus.dismissed:
        statusText = 'Dismissed';
        statusBgColor = AppColors.borderSecondary;
        statusTextColor = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            alert.description,
            style: AppTypography.manropeBold.copyWith(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${alert.stationId} · $location',
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: AppTypography.manropeMedium.copyWith(
                fontSize: 13,
                color: statusTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(
    Alert alert,
    String stationName,
    String location,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information',
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Station', stationName),
          _buildInfoRow('Location', location),
          _buildInfoRow(
            'Date',
            '${alert.timestamp.month}/${alert.timestamp.day}/${alert.timestamp.year}',
          ),
          _buildInfoRow('Time', _formatTime(alert.timestamp)),
          _buildInfoRow('Alert type', _getAlertTypeName(alert.type)),
          _buildInfoRow('Priority', _getSeverityName(alert.severity)),
          if (alert.snoozedUntil != null)
            _buildInfoRow(
              'Snoozed until',
              '${alert.snoozedUntil!.month}/${alert.snoozedUntil!.day} ${_formatTime(alert.snoozedUntil!)}',
            ),
          if (alert.assignedTechnicianId != null)
            _buildInfoRow(
              'Assigned to',
              'Technician (${alert.assignedTechnicianId})',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.manropeRegular.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.manropeMedium.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(DetectionEvent event) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Evidence',
                style: AppTypography.manropeSemiBold.copyWith(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _formatTime(event.timestamp),
                style: AppTypography.manropeRegular.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (event.evidenceImageUrl != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSecondary),
                image: DecorationImage(
                  image: AssetImage(event.evidenceImageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSecondary),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Captured evidence is unavailable.',
                    style: AppTypography.manropeRegular.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Species: ',
                style: AppTypography.manropeRegular.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                event.species.name.substring(0, 1).toUpperCase() +
                    event.species.name.substring(1),
                style: AppTypography.manropeMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Confidence: ',
                style: AppTypography.manropeRegular.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                event.confidenceScore != null
                    ? '${(event.confidenceScore! * 100).round()}%'
                    : '—',
                style: AppTypography.manropeMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, AlertDetailViewModel vm) {
    return Column(
      children: [
        if (vm.permissions?.canResolve == true)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.isMutating ? null : () => _confirmResolve(vm),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Mark as resolved'),
            ),
          ),
        const SizedBox(height: 12),
        if (vm.permissions?.canSnooze == true)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: vm.isMutating ? null : () => _confirmSnooze(vm),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.borderSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Snooze'),
            ),
          ),
        const SizedBox(height: 12),
        if (vm.permissions?.canAssign == true)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: vm.isMutating
                  ? null
                  : () {
                      _showAssignDialog(context, vm);
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.borderSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Assign to technician'),
            ),
          ),
        const SizedBox(height: 12),
        if (vm.permissions?.canDismiss == true)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: vm.isMutating ? null : () => _confirmDismiss(vm),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppColors.criticalRed,
              ),
              child: const Text('Dismiss alert'),
            ),
          ),
      ],
    );
  }

  void _showAssignDialog(BuildContext context, AlertDetailViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign Technician',
                  style: AppTypography.manropeBold.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  title: const Text('Ahmed Khan'),
                  subtitle: const Text('technician@baitguard.com'),
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  onTap: () {
                    Navigator.pop(ctx);
                    vm.assignAlert('tech_1');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  String _getAlertTypeName(AlertType type) {
    switch (type) {
      case AlertType.rodent:
        return 'Rodent';
      case AlertType.lowBait:
        return 'Low bait';
      case AlertType.tamper:
        return 'Tamper';
      case AlertType.stationOffline:
        return 'Offline';
    }
  }

  String _getSeverityName(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return 'High';
      case AlertSeverity.warning:
        return 'Medium';
      case AlertSeverity.info:
        return 'Low';
    }
  }
}
