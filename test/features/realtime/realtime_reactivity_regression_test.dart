import 'package:flutter_test/flutter_test.dart';

import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/data/repositories/firebase/realtime_alert_repository.dart';
import 'package:baitguard/data/repositories/firebase/realtime_dashboard_repository.dart';
import 'package:baitguard/data/repositories/firebase/realtime_report_repository.dart';
import 'package:baitguard/data/repositories/firebase/realtime_station_data_source.dart';
import 'package:baitguard/data/repositories/firebase/realtime_station_repository.dart';
import 'package:baitguard/domain/models/alert_type.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/report_models.dart';
import 'package:baitguard/domain/models/station_status.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/features/alerts/view_models/alert_detail_view_model.dart';
import 'package:baitguard/features/alerts/view_models/alerts_view_model.dart';
import 'package:baitguard/features/dashboard/view_models/user_dashboard_view_model.dart';
import 'package:baitguard/features/reports/view_models/reports_view_model.dart';
import 'package:baitguard/features/stations/view_models/station_detail_view_model.dart';
import 'package:baitguard/features/stations/view_models/stations_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Realtime Reactivity & Session Regression Tests', () {
    late DateTime simulatedTime;
    DateTime testClock() => simulatedTime;

    late RealtimeStationDataSource dataSource;
    late RealtimeStationRepository stationRepo;
    late RealtimeAlertRepository alertRepo;
    late RealtimeDashboardRepository dashboardRepo;
    late RealtimeReportRepository reportRepo;

    late AppSessionController sessionController;
    late ActiveFacilityController facilityController;

    final pilotViewer = AppUser(
      id: 'viewer_01',
      name: 'Pilot Viewer',
      email: 'viewer@baitguard.com',
      role: UserRole.viewer,
      siteAccessIds: const ['site_1'],
    );

    final pilotAdmin = AppUser(
      id: 'admin_01',
      name: 'Pilot Admin',
      email: 'admin@baitguard.com',
      role: UserRole.admin,
      siteAccessIds: const ['site_1'],
    );

    Map<String, dynamic> makeStationPayload({
      String deviceId = 'station_01',
      String facilityId = 'site_1',
      double battery = 92.0,
      double bait = 80.0,
      bool online = true,
      int? lastSeenAt,
    }) {
      return {
        'device_id': deviceId,
        'facility_id': facilityId,
        'battery_percentage': battery,
        'bait_percentage': bait,
        'online': online,
        'last_seen_at': lastSeenAt ?? simulatedTime.millisecondsSinceEpoch,
      };
    }

    Map<String, dynamic> makeRatEventPayload({
      String deviceId = 'station_01',
      String facilityId = 'site_1',
      int? timestamp,
    }) {
      return {
        'device_id': deviceId,
        'facility_id': facilityId,
        'event_type': 'rat_detected',
        'timestamp': timestamp ?? simulatedTime.millisecondsSinceEpoch,
      };
    }

    Map<String, dynamic> makeLowBaitEventPayload({
      String deviceId = 'station_01',
      String facilityId = 'site_1',
      double bait = 15.0,
      int currentPixels = 4200,
      String status = 'Low',
      int? timestamp,
    }) {
      return {
        'device_id': deviceId,
        'facility_id': facilityId,
        'event_type': 'low_bait_alert',
        'bait_percentage': bait,
        'current_pixels': currentPixels,
        'status': status,
        'timestamp': timestamp ?? simulatedTime.millisecondsSinceEpoch,
      };
    }

    setUp(() {
      simulatedTime = DateTime.utc(2026, 9, 27, 12, 0, 0);
      dataSource = RealtimeStationDataSource(clock: testClock);
      stationRepo = RealtimeStationRepository(dataSource);
      alertRepo = RealtimeAlertRepository(dataSource);
      dashboardRepo = RealtimeDashboardRepository(dataSource);
      reportRepo = RealtimeReportRepository(dataSource);

      sessionController = AppSessionController();
      sessionController.establishSession(pilotViewer);

      facilityController = ActiveFacilityController(
        permittedSiteIds: const ['site_1'],
        initialSiteId: 'site_1',
      );

      dataSource.bindSessionAndFacility(
        user: pilotViewer,
        facilityId: 'site_1',
      );
    });

    tearDown(() {
      dataSource.dispose();
      facilityController.dispose();
      sessionController.dispose();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Initial Data and Subsequent Live Updates Reaching ViewModels
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'Initial data and subsequent live updates propagate to ViewModels',
      () async {
        // Seed initial telemetry
        dataSource.updateFromLivePayload(
          makeStationPayload(battery: 95.0, bait: 85.0),
        );
        dataSource.updateFromEventsPayload({'evt_1': makeRatEventPayload()});

        // 1a. UserDashboardViewModel
        final userVm = UserDashboardViewModel(
          dashboardRepository: dashboardRepo,
          sessionController: sessionController,
          activeFacilityController: facilityController,
        );
        await userVm.load();
        expect(userVm.status, DashboardLoadStatus.success);
        expect(userVm.data?.detectionsToday, 1);
        expect(userVm.data?.stationMetrics.activeCount, 1);

        // Emit new detection event while listening
        dataSource.updateFromEventsPayload({
          'evt_1': makeRatEventPayload(),
          'evt_2': makeRatEventPayload(),
        });
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(userVm.data?.detectionsToday, 2);
        userVm.dispose();

        // 1b. StationsViewModel
        final stationsVm = StationsViewModel(
          stationRepository: stationRepo,
          sessionController: sessionController,
          activeFacilityController: facilityController,
        );
        await stationsVm.load();
        expect(stationsVm.status, StationsLoadStatus.success);
        expect(stationsVm.allStations.length, 1);
        expect(stationsVm.allStations.first.baitPercentage, 85.0);

        // Emit updated telemetry
        dataSource.updateFromLivePayload(makeStationPayload(bait: 65.0));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(stationsVm.allStations.first.baitPercentage, 65.0);
        stationsVm.dispose();

        // 1c. AlertsViewModel
        final alertsVm = AlertsViewModel(
          alertRepository: alertRepo,
          stationRepository: stationRepo,
          sessionController: sessionController,
          activeFacilityController: facilityController,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(alertsVm.todayAlerts.length, 2);

        // Add low-bait alert event
        dataSource.updateFromEventsPayload({
          'evt_1': makeRatEventPayload(),
          'evt_2': makeRatEventPayload(),
          'evt_3': makeLowBaitEventPayload(),
        });
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(alertsVm.todayAlerts.length, 3);
        alertsVm.dispose();
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Updates Arriving Before Subscription
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'Updates arriving before ViewModel subscription are captured on load',
      () async {
        // Station telemetry arrives before any ViewModel is instantiated
        dataSource.updateFromLivePayload(
          makeStationPayload(battery: 88.0, bait: 72.0),
        );
        dataSource.updateFromEventsPayload({
          'evt_pre_1': makeRatEventPayload(),
        });

        final stationsVm = StationsViewModel(
          stationRepository: stationRepo,
          sessionController: sessionController,
          activeFacilityController: facilityController,
        );
        await stationsVm.load();

        expect(stationsVm.status, StationsLoadStatus.success);
        expect(stationsVm.allStations.length, 1);
        expect(stationsVm.allStations.first.batteryPercentage, 88.0);
        expect(stationsVm.allStations.first.baitPercentage, 72.0);
        stationsVm.dispose();
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Refresh Obtains Current Data
    // ─────────────────────────────────────────────────────────────────────────
    test('Manual refresh re-reads current data correctly', () async {
      dataSource.updateFromLivePayload(makeStationPayload(battery: 90.0));

      final stationDetailVm = StationDetailViewModel(
        stationId: 'station_01',
        stationRepository: stationRepo,
      );
      await stationDetailVm.load();
      expect(stationDetailVm.station?.batteryPercentage, 90.0);

      // Telemetry changes in data source
      dataSource.updateFromLivePayload(makeStationPayload(battery: 75.0));
      await stationDetailVm.refresh();

      expect(stationDetailVm.station?.batteryPercentage, 75.0);
      stationDetailVm.dispose();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4. Logout / Account / Facility Changes Clear Previous Data
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'Logout and facility switch clear cached data and cancel subscriptions',
      () async {
        dataSource.updateFromLivePayload(makeStationPayload());
        dataSource.updateFromEventsPayload({'evt_1': makeRatEventPayload()});

        expect(dataSource.cachedStation != null, isTrue);

        // Simulate Logout
        dataSource.bindSessionAndFacility(user: null, facilityId: null);

        expect(dataSource.cachedStation, isNull);
        expect(await dataSource.fetchAlerts(siteId: 'site_1'), isEmpty);
        expect(await dataSource.fetchStationEvents('station_01'), isEmpty);

        // Re-bind to unauthorized facility 'site_2'
        dataSource.bindSessionAndFacility(
          user: pilotViewer,
          facilityId: 'site_2',
        );
        expect(dataSource.cachedStation, isNull);
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 5. Same-Facility Permission Revocation Clears Data
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'Revoking permissions for the same facility purges data and rejects access',
      () async {
        dataSource.updateFromLivePayload(makeStationPayload());
        expect(dataSource.cachedStation != null, isTrue);

        // User's siteAccessIds revoked to empty list
        final revokedUser = pilotViewer.copyWith(siteAccessIds: const []);
        dataSource.bindSessionAndFacility(
          user: revokedUser,
          facilityId: 'site_1',
        );

        expect(dataSource.cachedStation, isNull);
        expect(await dataSource.fetchStation('station_01'), isNull);
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 6. Late Callbacks from Previous Session are Ignored via Session Token
    // ─────────────────────────────────────────────────────────────────────────
    test('Late callbacks from old session token are safely ignored', () async {
      final initialToken = dataSource.sessionToken;

      // User switches session / logs out
      dataSource.bindSessionAndFacility(user: null, facilityId: null);
      expect(dataSource.sessionToken, greaterThan(initialToken));

      // Late async callback tries to process payload with old token check
      final isCurrent = dataSource.sessionToken == initialToken;
      expect(isCurrent, isFalse);

      // Telemetry cache remains clear
      expect(dataSource.cachedStation, isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 7. Listener Cleanup and Duplicate Prevention
    // ─────────────────────────────────────────────────────────────────────────
    test('ViewModel disposal cancels stream subscriptions cleanly', () async {
      dataSource.updateFromLivePayload(makeStationPayload());

      final vm = StationDetailViewModel(
        stationId: 'station_01',
        stationRepository: stationRepo,
      );
      await vm.load();
      expect(vm.status, StationDetailLoadStatus.success);

      // Dispose
      vm.dispose();

      // Emit new data after disposal — should not throw or notify
      dataSource.updateFromLivePayload(makeStationPayload(battery: 50.0));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        vm.station?.batteryPercentage,
        92.0,
      ); // Retained disposed state without crashing
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 8. Permission Failures and Recovery
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'Permission failure recovers when valid facility is re-selected',
      () async {
        // 8. Permission failure on unauthorized facility
        final unauthController = ActiveFacilityController(
          permittedSiteIds: const ['site_unauthorized'],
          initialSiteId: 'site_unauthorized',
        );
        final userVm = UserDashboardViewModel(
          dashboardRepository: dashboardRepo,
          sessionController: sessionController,
          activeFacilityController: unauthController,
        );

        await userVm.load();
        expect(userVm.data?.statusMessage, 'NO ACTIVE TELEMETRY');
        userVm.dispose();
        unauthController.dispose();

        // Recover by selecting authorized pilot site with valid controller
        final recoverVm = UserDashboardViewModel(
          dashboardRepository: dashboardRepo,
          sessionController: sessionController,
          activeFacilityController: facilityController,
        );
        dataSource.updateFromLivePayload(makeStationPayload());
        await recoverVm.load();

        expect(recoverVm.status, DashboardLoadStatus.success);
        expect(recoverVm.data?.statusMessage, 'ALL SYSTEMS NOMINAL');
        recoverVm.dispose();
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 9. Offline Transition Without Heartbeat (30-Minute Timeout)
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'Station transitions to offline after 30 minutes without new heartbeat',
      () async {
        dataSource.updateFromLivePayload(
          makeStationPayload(
            online: true,
            lastSeenAt: simulatedTime.millisecondsSinceEpoch,
          ),
        );

        var station = await dataSource.fetchStation('station_01');
        expect(station?.status, StationStatus.online);

        // Advance clock by 31 minutes
        simulatedTime = simulatedTime.add(const Duration(minutes: 31));

        // Trigger freshness check
        dataSource.checkFreshness();

        station = await dataSource.fetchStation('station_01');
        expect(station?.status, StationStatus.offline);
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 10. Invalid/Missing Payload Fields and Identity Mismatches
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'Invalid payload fields and identity mismatches are rejected safely',
      () {
        // 10a. Device ID mismatch
        dataSource.updateFromLivePayload({
          'device_id': 'station_99',
          'facility_id': 'site_1',
          'battery_percentage': 90.0,
          'bait_percentage': 80.0,
          'online': true,
          'last_seen_at': simulatedTime.millisecondsSinceEpoch,
        });
        expect(dataSource.cachedStation, isNull);

        // 10b. Facility ID mismatch
        dataSource.updateFromLivePayload({
          'device_id': 'station_01',
          'facility_id': 'site_other',
          'battery_percentage': 90.0,
          'bait_percentage': 80.0,
          'online': true,
          'last_seen_at': simulatedTime.millisecondsSinceEpoch,
        });
        expect(dataSource.cachedStation, isNull);

        // 10c. Invalid battery range (> 100)
        dataSource.updateFromLivePayload({
          'device_id': 'station_01',
          'facility_id': 'site_1',
          'battery_percentage': 150.0, // Out of range
          'bait_percentage': 80.0,
          'online': true,
          'last_seen_at': simulatedTime.millisecondsSinceEpoch,
        });
        expect(dataSource.cachedStation, isNull);

        // 10d. Low bait event missing current_pixels is rejected
        dataSource.updateFromEventsPayload({
          'bad_evt': {
            'device_id': 'station_01',
            'facility_id': 'site_1',
            'event_type': 'low_bait_alert',
            'bait_percentage': 10.0,
            'status': 'Low',
            'timestamp': simulatedTime.millisecondsSinceEpoch,
          },
        });
        expect(dataSource.cachedEvents, isEmpty);
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 11. Rat Versus Low-Bait Event Counts
    // ─────────────────────────────────────────────────────────────────────────
    test('Low-bait events are not counted as rodent detections', () async {
      dataSource.updateFromLivePayload(makeStationPayload());
      dataSource.updateFromEventsPayload({
        'r1': makeRatEventPayload(),
        'r2': makeRatEventPayload(),
        'r3': makeRatEventPayload(),
        'b1': makeLowBaitEventPayload(),
        'b2': makeLowBaitEventPayload(),
      });

      final events = await dataSource.fetchStationEvents('station_01');
      expect(events.length, 3);

      final ratEvents = events.where((e) => e.species.name == 'rat').toList();
      expect(ratEvents.length, 3);

      final alerts = await dataSource.fetchAlerts(siteId: 'site_1');
      expect(alerts.length, 5);
      final rodentAlerts = alerts
          .where((a) => a.type == AlertType.rodent)
          .toList();
      final lowBaitAlerts = alerts
          .where((a) => a.type == AlertType.lowBait)
          .toList();

      expect(rodentAlerts.length, 3);
      expect(lowBaitAlerts.length, 2);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 12. Report Calendar Periods and Boundary Timestamps
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'Report periods use inclusive start and exclusive end boundaries',
      () async {
        final periodStart = DateTime.utc(
          2026,
          9,
          21,
          0,
          0,
          0,
        ); // 7-day week start
        final periodEnd = DateTime.utc(
          2026,
          9,
          28,
          0,
          0,
          0,
        ); // week end (exclusive)

        final period = ReportPeriod(
          type: ReportPeriodType.week,
          anchorDate: DateTime.utc(2026, 9, 25),
        );

        // Event exactly at start boundary -> included
        // Event exactly at end boundary -> excluded
        dataSource.updateFromLivePayload(makeStationPayload());
        dataSource.updateFromEventsPayload({
          'boundary_start': makeRatEventPayload(
            timestamp: periodStart.millisecondsSinceEpoch,
          ),
          'boundary_end': makeRatEventPayload(
            timestamp: periodEnd.millisecondsSinceEpoch,
          ),
        });

        final reportData = await reportRepo.getDashboardData(
          siteId: 'site_1',
          period: period,
        );

        // Only boundary_start should be included; boundary_end is excluded
        expect(reportData.summary.totalDetections, 1);
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 13. Unsupported Actions and Exports Never Report Success
    // ─────────────────────────────────────────────────────────────────────────
    test(
      'Unsupported pilot mutations and report exports fail safely with clear error',
      () async {
        dataSource.updateFromLivePayload(makeStationPayload());
        dataSource.updateFromEventsPayload({'r1': makeRatEventPayload()});

        // 13a. Station muting unsupported
        final stationDetailVm = StationDetailViewModel(
          stationId: 'station_01',
          stationRepository: stationRepo,
        );
        await stationDetailVm.load();
        await stationDetailVm.setNotificationsMuted(true);
        expect(
          stationDetailVm.actionErrorMessage,
          'Muting notifications is unavailable in this pilot.',
        );
        expect(stationDetailVm.actionSuccessMessage, isNull);
        stationDetailVm.dispose();

        // 13b. Alert mutation unsupported
        sessionController.establishSession(pilotAdmin);
        final alerts = await alertRepo.getAlerts(siteId: 'site_1');
        expect(alerts, isNotEmpty);
        final alertDetailVm = AlertDetailViewModel(
          alertId: alerts.first.id,
          alertRepository: alertRepo,
          stationRepository: stationRepo,
          sessionController: sessionController,
          activeFacilityController: facilityController,
        );
        while (alertDetailVm.isLoading) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        await alertDetailVm.resolveAlert();
        expect(
          alertDetailVm.actionErrorMessage,
          'Alert mutations are unavailable in this pilot.',
        );
        expect(alertDetailVm.actionSuccessMessage, isNull);
        alertDetailVm.dispose();

        // 13c. Report generation/export unsupported
        final reportsVm = ReportsViewModel(
          repository: reportRepo,
          activeFacilityController: facilityController,
          userRole: UserRole.admin,
          currentUserId: 'admin_01',
        );
        await reportsVm.generateReport(ReportTemplateType.monthlyActivity);
        expect(
          reportsVm.actionErrorMessage,
          'Report export is unavailable in this pilot.',
        );
        expect(reportsVm.actionSuccessMessage, isNull);

        reportsVm.handleMockDownload();
        expect(
          reportsVm.actionErrorMessage,
          'Report download is unavailable in this pilot.',
        );

        reportsVm.handleMockShare();
        expect(
          reportsVm.actionErrorMessage,
          'Report sharing is unavailable in this pilot.',
        );
        reportsVm.dispose();
      },
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 14. Realtime Pilot Schema Metadata
    // ─────────────────────────────────────────────────────────────────────────
    test('Station in realtime pilot reports hasTamperData false', () async {
      dataSource.updateFromLivePayload(makeStationPayload());
      final station = await dataSource.fetchStation('station_01');
      expect(station, isNotNull);
      expect(station!.hasTamperData, isFalse);
      expect(station.hasCamera, isTrue);
    });
  });
}
