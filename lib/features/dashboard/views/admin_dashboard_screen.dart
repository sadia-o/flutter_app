import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../app/navigation/route_names.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/site.dart';
import '../../navigation/models/admin_alert_list_preset.dart';
import '../view_models/admin_dashboard_view_model.dart';
import '../view_models/user_dashboard_view_model.dart' show DashboardLoadStatus;

// Widgets
import '../widgets/activity_chart_card.dart';
import '../widgets/facility_map_card.dart';
import '../widgets/metric_summary_grid.dart';
import '../widgets/admin_quick_actions_card.dart';
import '../widgets/dashboard_alert_card.dart';

import '../widgets/species_breakdown_card.dart';
import '../widgets/admin_overview_card.dart';
import '../widgets/health_summary_card.dart';
import '../widgets/todays_detections_card.dart';
import '../widgets/critical_alerts_summary_card.dart';
import '../widgets/pending_user_requests_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  final void Function(int tabIndex, {AdminAlertListPreset preset}) onSelectTab;
  final ValueChanged<String>? onAlertTap;
  final VoidCallback? onReviewRequests;
  final VoidCallback? onManageSystem;
  final VoidCallback? onUsers;

  const AdminDashboardScreen({
    super.key,
    required this.onSelectTab,
    this.onAlertTap,
    this.onReviewRequests,
    this.onManageSystem,
    this.onUsers,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _lastRefreshErrorEventId = 0;
  int _lastFacilityErrorEventId = 0;
  final GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminDashboardViewModel>().addListener(_onViewModelChange);
      }
    });
  }

  void _onViewModelChange() {
    if (!mounted) return;
    final viewModel = context.read<AdminDashboardViewModel>();
    if (viewModel.refreshErrorEventId > _lastRefreshErrorEventId) {
      _lastRefreshErrorEventId = viewModel.refreshErrorEventId;
      if (viewModel.refreshErrorMessage != null) {
        AppTopToast.show(context, viewModel.refreshErrorMessage!);
      }
    }
    if (viewModel.facilityErrorEventId > _lastFacilityErrorEventId) {
      _lastFacilityErrorEventId = viewModel.facilityErrorEventId;
      if (viewModel.facilityErrorMessage != null) {
        AppTopToast.show(context, viewModel.facilityErrorMessage!);
      }
    }
  }

  void _scrollToMap() {
    if (_mapKey.currentContext != null) {
      Scrollable.ensureVisible(
        _mapKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminDashboardViewModel>();
    final sessionUser = context.watch<AppSessionController>().currentUser;

    if (viewModel.status == DashboardLoadStatus.initial ||
        viewModel.status == DashboardLoadStatus.loading &&
            viewModel.data == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AppLoadingState(message: 'Loading admin dashboard...'),
        ),
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
    final adminUser = sessionUser ?? viewModel.adminUser;

    // Avatar initials
    final nameParts = adminUser.name.trim().split(RegExp(r'\s+'));
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  // 1. Header
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
                              adminUser.name,
                              maxLines: 1,
                              style: AppTypography.manropeExtraBold.copyWith(
                                fontSize: 30,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Administrator',
                                style: AppTypography.manropeSemiBold.copyWith(
                                  fontSize: 10,
                                  color: AppColors.primaryBlue,
                                  letterSpacing: 0.5,
                                ),
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
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Site Selection Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Site>(
                        value: data.selectedSite,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                        items: data.availableSites.map((site) {
                          return DropdownMenuItem<Site>(
                            value: site,
                            child: Text(
                              site.name,
                              style: AppTypography.manropeSemiBold.copyWith(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (Site? newSite) {
                          if (newSite != null) {
                            viewModel.selectFacility(newSite.id);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 3. Admin Overview
                  AdminOverviewCard(
                    facilityCount: data.facilityCount,
                    userCount: data.userCount,
                    pendingRequestCount: data.pendingRequestCount,
                    systemStatus: data.systemStatus,
                    onManageSystem:
                        widget.onManageSystem ??
                        () => AppTopToast.show(
                          context,
                          'System management will be available shortly.',
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 4. Health Summary
                  HealthSummaryCard(
                    score: data.systemHealthScore,
                    scoreChange: data.healthScoreChange,
                    statusMessage: data.healthStatusMessage,
                    activeStations: data.stationMetrics.activeCount,
                    totalStations: data.stationMetrics.totalCount,
                    attentionStations: data.stationMetrics.offlineCount,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 5. Station Metric Cards
                  MetricSummaryGrid(
                    totalStations: data.stationMetrics.totalCount,
                    activeStations: data.stationMetrics.activeCount,
                    refillNeeded: data.stationMetrics.refillNeededCount,
                    offlineStations: data.stationMetrics.offlineCount,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 6. Today's Detections
                  TodaysDetectionsCard(
                    detectionsToday: data.detectionsToday,
                    detectionsChangePercentage: data.detectionsChangePercentage,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 7. Quick Actions
                  AdminQuickActionsCard(
                    lastUpdatedAt: data.lastUpdatedAt,
                    isRefreshing:
                        viewModel.status == DashboardLoadStatus.loading,
                    onRefresh: viewModel.refresh,
                    onMap: _scrollToMap,
                    onReports: () => widget.onSelectTab(3),
                    onUsers:
                        widget.onUsers ??
                        () => AppTopToast.show(
                          context,
                          'User management is unavailable.',
                        ),
                    onSettings: () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        RouteNames.settings,
                        arguments: context.read<ActiveFacilityController>(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 8. Critical Alerts
                  CriticalAlertsSummaryCard(
                    criticalCount: data.criticalAlertCount,
                    onViewAll: () {
                      widget.onSelectTab(
                        2,
                        preset: AdminAlertListPreset.criticalUnresolved,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 9. Live Facility Map
                  Container(
                    key: _mapKey,
                    child: FacilityMapCard(
                      markers: data.mapMarkers,
                      zones: data.facilityZones,
                      onMarkerTap: (stationId) {
                        AppTopToast.show(
                          context,
                          'Station details will be available shortly.',
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 10. Today's Activity
                  ActivityChartCard(
                    series: data.activitySeries,
                    detectionsToday: data.detectionsToday,
                    activityChangePercentage: data.detectionsChangePercentage,
                  ),

                  // 11. Pending User Requests
                  const SizedBox(height: AppSpacing.xxl),
                  PendingUserRequestsCard(
                    pendingCount: data.pendingRequestCount,
                    newTodayCount: data.newPendingRequestCountToday,
                    onReviewRequests:
                        widget.onReviewRequests ??
                        () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed(RouteNames.pendingRequests),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 12. Species Breakdown
                  SpeciesBreakdownCard(breakdown: data.speciesBreakdown),
                  const SizedBox(height: AppSpacing.xxl),

                  // 13. Recent Alerts
                  DashboardAlertCard(
                    title: 'Recent Alerts',
                    alerts: data.recentAlerts.take(6).toList(),
                    totalCount: data.totalAlertCount,
                    onSeeAll: () {
                      widget.onSelectTab(2, preset: AdminAlertListPreset.all);
                    },
                    onAlertTap: (alertId) {
                      if (widget.onAlertTap != null) {
                        widget.onAlertTap!(alertId);
                      }
                    },
                  ),

                  // 14. Bottom Navigation (Handled by AdminAppShell, just spacing here)
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
