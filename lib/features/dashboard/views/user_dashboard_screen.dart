import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../app/navigation/route_names.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../app/state/app_session_controller.dart';
import '../view_models/user_dashboard_view_model.dart';
import '../widgets/activity_chart_card.dart';
import '../widgets/facility_map_card.dart';
import '../widgets/health_summary_card.dart';
import '../widgets/metric_summary_grid.dart';
import '../widgets/quick_actions_card.dart';
import '../widgets/dashboard_alert_card.dart';

import '../widgets/species_breakdown_card.dart';

class UserDashboardScreen extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
  final ValueChanged<String>? onAlertTap;
  final ValueChanged<String>? onStationTap;

  const UserDashboardScreen({
    super.key,
    required this.onSelectTab,
    this.onAlertTap,
    this.onStationTap,
  });

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _lastErrorEventId = 0;

  @override
  void initState() {
    super.initState();
    // Delay adding listener to ensure we don't call show toast during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserDashboardViewModel>().addListener(_onViewModelChange);
      }
    });
  }

  @override
  void dispose() {
    // Only remove if we can safely read, but typical provider dispose handles this.
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;
    final viewModel = context.read<UserDashboardViewModel>();
    if (viewModel.refreshErrorEventId > _lastErrorEventId) {
      _lastErrorEventId = viewModel.refreshErrorEventId;
      if (viewModel.refreshErrorMessage != null) {
        AppTopToast.show(context, viewModel.refreshErrorMessage!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserDashboardViewModel>();
    final sessionUser = context.watch<AppSessionController>().currentUser;

    if (viewModel.status == DashboardLoadStatus.initial ||
        viewModel.status == DashboardLoadStatus.loading &&
            viewModel.data == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: AppLoadingState(message: 'Loading dashboard...')),
      );
    }

    if (viewModel.status == DashboardLoadStatus.failure &&
        viewModel.data == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AppErrorState(
            message: viewModel.errorMessage ?? 'An error occurred.',
            onRetry: viewModel.load,
          ),
        ),
      );
    }

    final data = viewModel.data!;
    final user = sessionUser ?? data.user;

    // Determine user name initials for avatar
    final nameParts = user.name.trim().split(RegExp(r'\s+'));
    final initials = nameParts.length > 1
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : (nameParts.isNotEmpty && nameParts[0].isNotEmpty
              ? nameParts[0]
                    .substring(0, min(2, nameParts[0].length))
                    .toUpperCase()
              : '?');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning,',
                              style: AppTypography.manropeRegular.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.manropeExtraBold.copyWith(
                                fontSize: 30,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => widget.onSelectTab(2),
                            child: Semantics(
                              label: 'Notification Button',
                              button: true,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(
                                      Icons.notifications_none,
                                      color: AppColors.textPrimary,
                                      size: 24,
                                    ),
                                    if (data.unreadAlertCount > 0)
                                      Positioned(
                                        right: 2,
                                        top: 2,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.criticalRed,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamed(
                                RouteNames.settings,
                                arguments: context
                                    .read<ActiveFacilityController>(),
                              );
                            },
                            child: Semantics(
                              label: 'Avatar',
                              button: true,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: AppTypography.manropeBold.copyWith(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  HealthSummaryCard(
                    score: data.healthScore,
                    scoreChange: data.healthScoreChange,
                    statusMessage: data.statusMessage,
                    activeStations: data.stationMetrics.activeCount,
                    totalStations: data.stationMetrics.totalCount,
                    attentionStations: data.stationMetrics.offlineCount,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  MetricSummaryGrid(
                    totalStations: data.stationMetrics.totalCount,
                    activeStations: data.stationMetrics.activeCount,
                    refillNeeded: data.stationMetrics.refillNeededCount,
                    offlineStations: data.stationMetrics.offlineCount,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  QuickActionsCard(
                    lastUpdatedAt: data.lastUpdatedAt,
                    isRefreshing:
                        viewModel.status == DashboardLoadStatus.loading,
                    onRefresh: viewModel.refresh,
                    onMap: () => widget.onSelectTab(1),
                    onReport: () => widget.onSelectTab(3),
                    onSettings: () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        RouteNames.settings,
                        arguments: context.read<ActiveFacilityController>(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  FacilityMapCard(
                    markers: data.mapMarkers,
                    zones: data.facilityZones,
                    onMarkerTap: (stationId) {
                      if (widget.onStationTap != null) {
                        widget.onStationTap!(stationId);
                      } else {
                        AppTopToast.show(
                          context,
                          'Station Detail for $stationId will be available shortly.',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  ActivityChartCard(
                    series: data.activitySeries,
                    detectionsToday: data.detectionsToday,
                    activityChangePercentage: data.activityChangePercentage,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  SpeciesBreakdownCard(breakdown: data.speciesBreakdown),
                  const SizedBox(height: AppSpacing.xxl),

                  DashboardAlertCard(
                    alerts: data.recentAlerts,
                    onSeeAll: () => widget.onSelectTab(2),
                    onAlertTap: (alertId) {
                      if (widget.onAlertTap != null) {
                        widget.onAlertTap!(alertId);
                      }
                    },
                  ),
                  const SizedBox(
                    height: AppSpacing.xxl * 2,
                  ), // Extra padding at bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}
