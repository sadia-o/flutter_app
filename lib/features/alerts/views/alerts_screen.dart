import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../domain/models/alert.dart';
import '../../../domain/models/alert_status.dart';
import '../view_models/alerts_view_model.dart';
import '../models/alert_list_filter.dart';
import 'widgets/alert_severity_summary_card.dart';
import 'widgets/alert_row.dart';
import 'widgets/critical_attention_banner.dart';
import 'widgets/hotspot_station_row.dart';
import '../../../core/widgets/app_top_toast.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _lastRefreshErrorEventId = 0;
  int _lastActionSuccessEventId = 0;
  int _lastActionErrorEventId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AlertsViewModel>().addListener(_onViewModelChange);
      }
    });
  }

  void _onViewModelChange() {
    if (!mounted) return;
    final vm = context.read<AlertsViewModel>();

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

  Future<void> _confirmResolve(AlertsViewModel vm, Alert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Alert'),
        content: Text('Are you sure you want to resolve alert ${alert.id}?'),
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
      vm.resolveAlert(alert.id);
    }
  }

  Future<void> _confirmSnooze(AlertsViewModel vm, Alert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Snooze Alert'),
        content: Text('Snooze alert ${alert.id} for 1 hour?'),
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
      vm.snoozeAlert(alert.id, DateTime.now().add(const Duration(hours: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlertsViewModel>();

    if (vm.isLoading && vm.todayAlerts.isEmpty && vm.earlierAlerts.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (vm.error != null &&
        vm.todayAlerts.isEmpty &&
        vm.earlierAlerts.isEmpty) {
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
                onPressed: () => context.read<AlertsViewModel>().refresh(),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () => context.read<AlertsViewModel>().refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(vm),
                    const SizedBox(height: 24),
                    _buildSeverityCards(vm),
                    const SizedBox(height: 24),
                    _buildCriticalBanner(vm),
                    const SizedBox(height: 24),
                    _buildFilters(vm),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildAlertSection(
              context,
              title: _getPrimarySectionTitle(vm.selectedFilter),
              alerts: vm.todayAlerts,
              vm: vm,
            ),
            _buildAlertSection(
              context,
              title: 'Earlier',
              alerts: vm.earlierAlerts,
              vm: vm,
            ),
            if (vm.todayAlerts.isEmpty && vm.earlierAlerts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  child: Center(
                    child: Text(
                      'No alerts match this filter.',
                      style: AppTypography.manropeRegular.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildActivityChart(vm),
                    const SizedBox(height: 32),
                    _buildHotspots(vm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AlertsViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts',
          style: AppTypography.manropeBold.copyWith(
            fontSize: 24,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${vm.unreadCount} unread · ${vm.unresolvedCount} unresolved',
          style: AppTypography.manropeRegular.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityCards(AlertsViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: AlertSeveritySummaryCard(
            label: 'High',
            count: vm.highCount,
            color: AppColors.criticalRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AlertSeveritySummaryCard(
            label: 'Medium',
            count: vm.mediumCount,
            color: AppColors.warningAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AlertSeveritySummaryCard(
            label: 'Low',
            count: vm.lowCount,
            color: AppColors.primaryBlue, // or textSecondary/info
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalBanner(AlertsViewModel vm) {
    final criticals = vm.criticalUnresolvedAlerts;
    if (criticals.isEmpty) return const SizedBox.shrink();

    final stationIds = criticals.map((a) => a.stationId).toSet().toList();
    final stationText = stationIds.join(' & ');

    return CriticalAttentionBanner(
      count: criticals.length,
      stationIdsText: stationText,
      onTap: () {
        vm.setFilter(AlertListFilter.all);
      },
    );
  }

  Widget _buildFilters(AlertsViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AlertListFilter.values.map((filter) {
          final isSelected = vm.selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_getFilterName(filter)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  vm.setFilter(filter);
                }
              },
              selectedColor: AppColors.primaryBlue,
              backgroundColor: Colors.white,
              labelStyle: AppTypography.manropeRegular.copyWith(
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.borderSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterName(AlertListFilter filter) {
    switch (filter) {
      case AlertListFilter.all:
        return 'All';
      case AlertListFilter.rodent:
        return 'Rodent';
      case AlertListFilter.lowBait:
        return 'Low bait';
      case AlertListFilter.tamper:
        return 'Tamper';
      case AlertListFilter.offline:
        return 'Offline';
    }
  }

  String _getPrimarySectionTitle(AlertListFilter filter) {
    return 'Today';
  }

  Widget _buildAlertSection(
    BuildContext context, {
    required String title,
    required List<Alert> alerts,
    required AlertsViewModel vm,
  }) {
    if (alerts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((ctx, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                title,
                style: AppTypography.manropeBold.copyWith(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }
          final alert = alerts[index - 1];
          final station = vm.getStationForAlert(alert.id);
          return AlertRow(
            alert: alert,
            stationLocation: station?.locationDescription ?? 'Unknown location',
            onTap: () async {
              final result = await Navigator.of(
                context,
              ).pushNamed('/alert-detail', arguments: alert.id);
              if (result is Alert && context.mounted) {
                vm.applyUpdatedAlert(result);
              }
            },
            onResolve:
                vm.permissions?.canResolve == true &&
                    alert.status != AlertStatus.resolved &&
                    alert.status != AlertStatus.dismissed
                ? () => _confirmResolve(vm, alert)
                : null,
            onSnooze:
                vm.permissions?.canSnooze == true &&
                    alert.status != AlertStatus.resolved &&
                    alert.status != AlertStatus.dismissed
                ? () => _confirmSnooze(vm, alert)
                : null,
          );
        }, childCount: alerts.length + 1),
      ),
    );
  }

  Widget _buildActivityChart(AlertsViewModel vm) {
    final activity = vm.sevenDayActivity;
    if (activity.isEmpty) return const SizedBox.shrink();

    // Max count for Y axis scaling
    final maxY = activity
        .map((e) => e.count)
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();
    final topY = (maxY + 5).ceilToDouble(); // give some padding

    final spots = activity.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This week',
          style: AppTypography.manropeSemiBold.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 150,
          padding: const EdgeInsets.only(
            top: 16,
            right: 16,
            bottom: 8,
            left: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSecondary),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < activity.length) {
                        final date = activity[idx].day;
                        final weekday = const [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ][date.weekday - 1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            weekday,
                            style: AppTypography.manropeMedium.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    interval: 1,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (activity.length - 1).toDouble(),
              minY: 0,
              maxY: topY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.criticalRed,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.criticalRed.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHotspots(AlertsViewModel vm) {
    final hotspots = vm.hotspotStations;
    if (hotspots.isEmpty) return const SizedBox.shrink();

    final maxCount = hotspots.first.alertCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotspot stations',
          style: AppTypography.manropeSemiBold.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSecondary),
          ),
          child: Column(
            children: hotspots.map((h) {
              return HotspotStationRow(
                hotspot: h,
                maxCount: maxCount,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamed('/station-detail', arguments: h.stationId);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
