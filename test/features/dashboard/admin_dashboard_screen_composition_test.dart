import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baitguard/domain/models/dashboard/admin_dashboard_data.dart';
import 'package:baitguard/domain/models/dashboard/dashboard_system_status.dart';
import 'package:baitguard/domain/models/dashboard/station_summary_metrics.dart';
import 'package:baitguard/domain/models/site.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/features/dashboard/views/admin_dashboard_screen.dart';
import 'package:baitguard/features/dashboard/view_models/admin_dashboard_view_model.dart';
import 'package:baitguard/features/dashboard/view_models/user_dashboard_view_model.dart'
    show DashboardLoadStatus;
import 'package:baitguard/features/dashboard/widgets/admin_overview_card.dart';
import 'package:baitguard/features/dashboard/widgets/health_summary_card.dart';
import 'package:baitguard/features/dashboard/widgets/metric_summary_grid.dart';
import 'package:baitguard/features/dashboard/widgets/todays_detections_card.dart';
import 'package:baitguard/features/dashboard/widgets/admin_quick_actions_card.dart';
import 'package:baitguard/features/dashboard/widgets/critical_alerts_summary_card.dart';
import 'package:baitguard/features/dashboard/widgets/facility_map_card.dart';
import 'package:baitguard/features/dashboard/widgets/activity_chart_card.dart';
import 'package:baitguard/features/dashboard/widgets/pending_user_requests_card.dart';
import 'package:baitguard/features/dashboard/widgets/species_breakdown_card.dart';
import 'package:baitguard/features/dashboard/widgets/dashboard_alert_card.dart';
import 'package:baitguard/features/navigation/models/admin_alert_list_preset.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/app/state/active_facility_controller.dart';

class MockAdminDashboardViewModel extends ChangeNotifier
    implements AdminDashboardViewModel {
  @override
  DashboardLoadStatus status = DashboardLoadStatus.success;

  @override
  String? errorMessage;

  @override
  String? refreshErrorMessage;

  @override
  int refreshErrorEventId = 0;

  @override
  AppUser get adminUser => AppUser(
    id: 'admin1',
    name: 'Alex Rivera',
    email: 'alex@example.com',
    role: UserRole.admin,
  );

  @override
  get dashboardRepository => throw UnimplementedError();

  @override
  get sessionController => throw UnimplementedError();

  @override
  get activeFacilityController => throw UnimplementedError();

  @override
  get accessRequestRepository => null;

  @override
  int facilityErrorEventId = 0;

  @override
  String? facilityErrorMessage;

  AdminDashboardData? _data;

  @override
  AdminDashboardData? get data => _data;

  void setData(AdminDashboardData newData) {
    _data = newData;
    notifyListeners();
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> refreshPendingCounts() async {}

  @override
  Future<void> pendingRequestReviewed(DateTime? submittedAt) async {}

  @override
  Future<void> selectFacility(String siteId) async {}
}

void main() {
  Widget buildTestableWidget(
    AdminDashboardViewModel viewModel, {
    AppSessionController? sessionController,
    VoidCallback? onReviewRequests,
  }) {
    final session = sessionController ?? AppSessionController();
    if (!session.isAuthenticated) {
      session.establishSession(viewModel.adminUser);
    }
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSessionController>.value(value: session),
          ChangeNotifierProvider<ActiveFacilityController>(
            create: (_) =>
                ActiveFacilityController(permittedSiteIds: const ['site1']),
          ),
          ChangeNotifierProvider<AdminDashboardViewModel>.value(
            value: viewModel,
          ),
        ],
        child: AdminDashboardScreen(
          onSelectTab: (index, {AdminAlertListPreset? preset}) {},
          onReviewRequests: onReviewRequests,
        ),
      ),
    );
  }

  AdminDashboardData createMockData({int pendingRequestCount = 3}) {
    final sites = [
      const Site(id: 'site1', name: 'Warehouse A', location: 'Location A'),
      const Site(id: 'site2', name: 'Warehouse B', location: 'Location B'),
      const Site(id: 'site3', name: 'Warehouse C', location: 'Location C'),
      const Site(id: 'site4', name: 'Warehouse D', location: 'Location D'),
      const Site(id: 'site5', name: 'Warehouse E', location: 'Location E'),
    ];
    return AdminDashboardData(
      selectedSite: sites[0],
      availableSites: sites,
      lastUpdatedAt: DateTime.now(),
      userCount: 28,
      pendingRequestCount: pendingRequestCount,
      newPendingRequestCountToday: 2,
      systemStatus: DashboardSystemStatus.healthy,
      systemHealthScore: 87,
      healthScoreChange: 3,
      healthStatusMessage: 'ALL SYSTEMS NOMINAL',
      stationMetrics: const StationSummaryMetrics(
        totalCount: 120,
        activeCount: 118,
        offlineCount: 2,
        refillNeededCount: 8,
      ),
      detectionsToday: 42,
      detectionsChangePercentage: 12.0,
      criticalAlertCount: 3,
      unreadAlertCount: 1,
      totalAlertCount: 12,
      recentAlerts: [],
      activitySeries: [],
      speciesBreakdown: [],
      mapMarkers: [],
      facilityZones: [],
    );
  }

  group('AdminDashboardScreen Composition', () {
    late MockAdminDashboardViewModel viewModel;

    setUp(() {
      viewModel = MockAdminDashboardViewModel();
      viewModel.setData(createMockData());
    });

    testWidgets('Header and facility selector are rendered first', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));

      expect(find.text('Good morning,'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('Warehouse A'), findsOneWidget);
    });

    testWidgets('header reacts to session identity and handles long names', (
      WidgetTester tester,
    ) async {
      final session = AppSessionController()
        ..establishSession(viewModel.adminUser);
      await tester.pumpWidget(
        buildTestableWidget(viewModel, sessionController: session),
      );

      session.establishSession(
        viewModel.adminUser.copyWith(
          name: 'Muhammad Abdul Rehman Khan',
          firstName: 'Muhammad',
          lastName: 'Abdul Rehman Khan',
        ),
      );
      await tester.pump();

      expect(find.text('Muhammad Abdul Rehman Khan'), findsOneWidget);
      expect(find.text('MA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Admin Overview appears after facility selector and displays correct data',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(viewModel));

        final overviewFinder = find.byType(AdminOverviewCard);
        expect(overviewFinder, findsOneWidget);

        expect(
          find.descendant(of: overviewFinder, matching: find.text('5')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: overviewFinder, matching: find.text('28')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: overviewFinder, matching: find.text('3')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: overviewFinder, matching: find.text('Healthy')),
          findsOneWidget,
        );

        // Manage System appears inside Admin Overview
        expect(
          find.descendant(
            of: overviewFinder,
            matching: find.text('Manage System'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('HealthSummaryCard appears with correct data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));

      final healthFinder = find.byType(HealthSummaryCard);
      expect(healthFinder, findsOneWidget);

      expect(
        find.descendant(of: healthFinder, matching: find.text('87')),
        findsOneWidget,
      );

      final semanticsFinder = find.descendant(
        of: healthFinder,
        matching: find.bySemanticsLabel(RegExp(r'.*2 need attention.*')),
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Station metrics appear', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));
      expect(find.byType(MetricSummaryGrid), findsOneWidget);
    });

    testWidgets('Today\'s Detections appear and displays 42 and 12%', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));

      final detectionsFinder = find.byType(TodaysDetectionsCard);
      expect(detectionsFinder, findsOneWidget);

      expect(
        find.descendant(of: detectionsFinder, matching: find.text('42')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detectionsFinder, matching: find.text('+12%')),
        findsOneWidget,
      );
    });

    testWidgets('Quick Actions are correctly composed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));

      final quickActionsFinder = find.byType(AdminQuickActionsCard);
      expect(quickActionsFinder, findsOneWidget);

      expect(
        find.descendant(
          of: quickActionsFinder,
          matching: find.text('Quick Actions'),
        ),
        findsOneWidget,
      );
      expect(find.text('Admin Actions'), findsNothing);

      expect(
        find.descendant(of: quickActionsFinder, matching: find.text('Refresh')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: quickActionsFinder, matching: find.text('Map')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: quickActionsFinder, matching: find.text('Reports')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: quickActionsFinder, matching: find.text('Users')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: quickActionsFinder,
          matching: find.text('Settings'),
        ),
        findsOneWidget,
      );

      // Manage System and Review Requests should not be Quick Actions
      expect(
        find.descendant(
          of: quickActionsFinder,
          matching: find.text('Manage System'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: quickActionsFinder,
          matching: find.text('Review Requests'),
        ),
        findsNothing,
      );
    });

    testWidgets('Critical Alerts summary displays count 3', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();

      final criticalFinder = find.byType(CriticalAlertsSummaryCard);
      expect(criticalFinder, findsOneWidget);
      expect(
        find.descendant(
          of: criticalFinder,
          matching: find.text('3 stations require immediate attention'),
        ),
        findsOneWidget,
      );

      // Detailed Critical unresolved alerts list is absent from Home
      expect(find.text('Critical unresolved alerts'), findsNothing);
    });

    testWidgets('Live Facility Map appears', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FacilityMapCard), findsOneWidget);
    });

    testWidgets('Today\'s Activity appears', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1500),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActivityChartCard), findsOneWidget);
    });

    testWidgets('Pending User Requests remains visible at zero', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();

      final pendingFinder = find.byType(PendingUserRequestsCard);
      expect(pendingFinder, findsOneWidget);
      expect(
        find.descendant(
          of: pendingFinder,
          matching: find.text('Review Requests'),
        ),
        findsOneWidget,
      );

      viewModel.setData(createMockData(pendingRequestCount: 0));
      await tester.pumpWidget(buildTestableWidget(viewModel));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(PendingUserRequestsCard),
          matching: find.text('Review Requests'),
        ),
        findsOneWidget,
      );
      expect(find.text('No pending requests'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PendingUserRequestsCard),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Review Requests invokes Pending Requests navigation contract',
      (WidgetTester tester) async {
        var opened = false;
        await tester.pumpWidget(
          buildTestableWidget(viewModel, onReviewRequests: () => opened = true),
        );
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -2200),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Review Requests'));

        expect(opened, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Species Breakdown appears', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesBreakdownCard), findsOneWidget);
    });

    testWidgets('Recent Alerts displays View All (12)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();

      final recentFinder = find.byType(DashboardAlertCard);
      expect(recentFinder, findsOneWidget);

      expect(
        find.descendant(of: recentFinder, matching: find.text('Recent Alerts')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: recentFinder, matching: find.text('View All (12)')),
        findsOneWidget,
      );
    });

    testWidgets('Widget order verification', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(viewModel));
      await tester.pumpAndSettle();

      // Using finder positions to verify order
      final headerFinder = find.text('Good morning,');
      final overviewFinder = find.byType(AdminOverviewCard);
      final healthFinder = find.byType(HealthSummaryCard);
      final metricFinder = find.byType(MetricSummaryGrid);
      final detectionsFinder = find.byType(TodaysDetectionsCard);
      final quickActionsFinder = find.byType(AdminQuickActionsCard);
      final criticalFinder = find.byType(CriticalAlertsSummaryCard);
      final mapFinder = find.byType(FacilityMapCard);
      final activityFinder = find.byType(ActivityChartCard);
      final pendingFinder = find.byType(PendingUserRequestsCard);
      final speciesFinder = find.byType(SpeciesBreakdownCard);
      final recentFinder = find.byType(DashboardAlertCard);

      expect(
        tester.getTopLeft(headerFinder).dy,
        lessThan(tester.getTopLeft(overviewFinder).dy),
      );
      expect(
        tester.getTopLeft(overviewFinder).dy,
        lessThan(tester.getTopLeft(healthFinder).dy),
      );
      expect(
        tester.getTopLeft(healthFinder).dy,
        lessThan(tester.getTopLeft(metricFinder).dy),
      );
      expect(
        tester.getTopLeft(metricFinder).dy,
        lessThan(tester.getTopLeft(detectionsFinder).dy),
      );
      expect(
        tester.getTopLeft(detectionsFinder).dy,
        lessThan(tester.getTopLeft(quickActionsFinder).dy),
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(quickActionsFinder).dy,
        lessThan(tester.getTopLeft(criticalFinder).dy),
      );
      expect(
        tester.getTopLeft(criticalFinder).dy,
        lessThan(tester.getTopLeft(mapFinder).dy),
      );
      expect(
        tester.getTopLeft(mapFinder).dy,
        lessThan(tester.getTopLeft(activityFinder).dy),
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(activityFinder).dy,
        lessThan(tester.getTopLeft(pendingFinder).dy),
      );
      expect(
        tester.getTopLeft(pendingFinder).dy,
        lessThan(tester.getTopLeft(speciesFinder).dy),
      );
      expect(
        tester.getTopLeft(speciesFinder).dy,
        lessThan(tester.getTopLeft(recentFinder).dy),
      );
    });
  });
}
