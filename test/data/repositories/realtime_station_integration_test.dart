import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/data/repositories/firebase/realtime_station_data_source.dart';
import 'package:baitguard/data/repositories/firebase/realtime_station_repository.dart';
import 'package:baitguard/data/repositories/firebase/realtime_alert_repository.dart';
import 'package:baitguard/data/repositories/firebase/realtime_dashboard_repository.dart';
import 'package:baitguard/data/repositories/firebase/realtime_report_repository.dart';
import 'package:baitguard/domain/models/alert_severity.dart';
import 'package:baitguard/domain/models/alert_status.dart';
import 'package:baitguard/domain/models/alert_type.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/detected_species.dart';
import 'package:baitguard/domain/models/detection_event.dart';
import 'package:baitguard/domain/models/register_station_request.dart';
import 'package:baitguard/domain/models/report_models.dart';
import 'package:baitguard/domain/models/station_status.dart';
import 'package:baitguard/domain/models/user_role.dart';

void main() {
  group('RealtimeStationDataSource — Static Parsing', () {
    test('parseStationLive parses healthy online telemetry correctly', () {
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final payload = {
        'device_id': 'station_01',
        'facility_id': 'site_1',
        'battery_percentage': 86,
        'bait_percentage': 100,
        'online': true,
        'last_seen_at': nowMillis,
      };

      final station = RealtimeStationDataSource.parseStationLive(payload);

      expect(station, isNotNull);
      expect(station!.id, 'station_01');
      expect(station.siteId, 'site_1');
      expect(station.batteryPercentage, 86.0);
      expect(station.baitPercentage, 100.0);
      expect(station.status, StationStatus.online);
      expect(station.isOnline, isTrue);
      expect(station.hasCamera, isTrue);
    });

    test('parseStationLive marks station as lowBait when bait is <= 25%', () {
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final payload = {
        'device_id': 'station_01',
        'facility_id': 'site_1',
        'battery_percentage': 50,
        'bait_percentage': 20,
        'online': true,
        'last_seen_at': nowMillis,
      };

      final station = RealtimeStationDataSource.parseStationLive(payload);

      expect(station, isNotNull);
      expect(station!.status, StationStatus.lowBait);
      expect(station.isOnline, isTrue);
    });

    test(
      'parseStationLive marks station as offline when online flag is false',
      () {
        final nowMillis = DateTime.now().millisecondsSinceEpoch;
        final payload = {
          'device_id': 'station_01',
          'facility_id': 'site_1',
          'battery_percentage': 50,
          'bait_percentage': 80,
          'online': false,
          'last_seen_at': nowMillis,
        };

        final station = RealtimeStationDataSource.parseStationLive(payload);

        expect(station, isNotNull);
        expect(station!.status, StationStatus.offline);
        expect(station.isOnline, isFalse);
      },
    );

    test(
      'parseStationLive marks station as offline when last_seen_at is stale (>30m)',
      () {
        final staleMillis = DateTime.now()
            .subtract(const Duration(minutes: 45))
            .millisecondsSinceEpoch;
        final payload = {
          'device_id': 'station_01',
          'facility_id': 'site_1',
          'battery_percentage': 90,
          'bait_percentage': 90,
          'online': true,
          'last_seen_at': staleMillis,
        };

        final station = RealtimeStationDataSource.parseStationLive(payload);

        expect(station, isNotNull);
        expect(station!.status, StationStatus.offline);
        expect(station.isOnline, isFalse);
      },
    );

    test('parseStationLive returns null for null or non-map payloads', () {
      expect(RealtimeStationDataSource.parseStationLive(null), isNull);
      expect(RealtimeStationDataSource.parseStationLive('invalid'), isNull);
      expect(RealtimeStationDataSource.parseStationLive([]), isNull);
    });

    test(
      'parseStationEventsMap parses rat_detected and low_bait_alert correctly',
      () {
        final nowMillis = DateTime.now().millisecondsSinceEpoch;
        final olderMillis = nowMillis - 10000;

        final eventsPayload = {
          'evt_001': {
            'device_id': 'station_01',
            'facility_id': 'site_1',
            'event_type': 'rat_detected',
            'timestamp': olderMillis,
          },
          'evt_002': {
            'device_id': 'station_01',
            'facility_id': 'site_1',
            'event_type': 'low_bait_alert',
            'bait_percentage': 15,
            'current_pixels': 450,
            'status': 'Refill Required',
            'timestamp': nowMillis,
          },
        };

        final parsed = RealtimeStationDataSource.parseStationEventsMap(
          eventsPayload,
        );

        // Newest event first
        expect(parsed.alerts.length, 2);
        expect(parsed.events.length, 1);

        // evt_002 is newest, so alerts[0] is the low_bait_alert
        final lowBaitAlert = parsed.alerts.firstWhere(
          (a) => a.id == 'alert_evt_002',
        );
        expect(lowBaitAlert.type, AlertType.lowBait);
        expect(lowBaitAlert.severity, AlertSeverity.warning);
        expect(lowBaitAlert.status, AlertStatus.open);
        expect(lowBaitAlert.description, contains('15%'));

        // evt_001 rat detection
        final ratAlert = parsed.alerts.firstWhere(
          (a) => a.id == 'alert_evt_001',
        );
        expect(ratAlert.type, AlertType.rodent);
        expect(ratAlert.severity, AlertSeverity.critical);
        expect(ratAlert.detectionEventId, 'evt_001');

        final detection = parsed.events.first;
        expect(detection.id, 'evt_001');
        expect(detection.stationId, 'station_01');
        expect(detection.species, DetectedSpecies.rat);
        expect(detection.status, DetectionEventStatus.open);
        expect(detection.alertId, 'alert_evt_001');
      },
    );
  });

  group('Realtime Repositories Integration', () {
    late RealtimeStationDataSource dataSource;
    late RealtimeStationRepository stationRepo;
    late RealtimeAlertRepository alertRepo;
    late RealtimeDashboardRepository dashboardRepo;
    late RealtimeReportRepository reportRepo;

    final testUser = AppUser(
      id: 'test_tech_1',
      name: 'Test Technician',
      email: 'tech@baitguard.io',
      role: UserRole.technician,
      siteAccessIds: const ['site_1'],
    );

    setUp(() {
      dataSource = RealtimeStationDataSource();
      stationRepo = RealtimeStationRepository(dataSource);
      alertRepo = RealtimeAlertRepository(dataSource);
      dashboardRepo = RealtimeDashboardRepository(dataSource);
      reportRepo = RealtimeReportRepository(dataSource);

      // Seed mock telemetry and events into datasource cache
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      dataSource.updateFromLivePayload({
        'device_id': 'station_01',
        'facility_id': 'site_1',
        'battery_percentage': 86,
        'bait_percentage': 100,
        'online': true,
        'last_seen_at': nowMillis,
      });

      dataSource.updateFromEventsPayload({
        'evt_101': {
          'device_id': 'station_01',
          'facility_id': 'site_1',
          'event_type': 'rat_detected',
          'timestamp': nowMillis,
        },
        'evt_102': {
          'device_id': 'station_01',
          'facility_id': 'site_1',
          'event_type': 'low_bait_alert',
          'bait_percentage': 20,
          'current_pixels': 500,
          'status': 'Refill Required',
          'timestamp': nowMillis - 5000,
        },
      });
    });

    tearDown(() {
      dataSource.dispose();
    });

    test(
      'RealtimeStationRepository enforces facility isolation and queries',
      () async {
        // Querying pilot facility site_1 returns station_01
        final stationsSite1 = await stationRepo.getStations(siteId: 'site_1');
        expect(stationsSite1.length, 1);
        expect(stationsSite1.first.id, 'station_01');
        expect(stationsSite1.first.siteId, 'site_1');

        // Querying another facility returns empty list
        final stationsSite2 = await stationRepo.getStations(siteId: 'site_2');
        expect(stationsSite2, isEmpty);

        // getStationById
        final found = await stationRepo.getStationById('station_01');
        expect(found, isNotNull);
        expect(found!.id, 'station_01');

        final notFound = await stationRepo.getStationById('station_99');
        expect(notFound, isNull);

        // getStationEvents
        final events = await stationRepo.getStationEvents('station_01');
        expect(events.length, 1);
        expect(events.first.id, 'evt_101');

        final noEvents = await stationRepo.getStationEvents('station_99');
        expect(noEvents, isEmpty);
      },
    );

    test('RealtimeStationRepository blocks mutations safely', () async {
      expect(
        () => stationRepo.recordRefill('station_01'),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => stationRepo.setNotificationsMuted(
          stationId: 'station_01',
          muted: true,
        ),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => stationRepo.registerStation(
          RegisterStationRequest(
            stationId: 'st_01',
            stationName: 'New Station',
            siteId: 'site_1',
            zoneLocation: 'Zone B',
            connectivityType: StationConnectivityType.wifi,
            alertPreferences: StationAlertPreferences.defaults(),
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
      'RealtimeAlertRepository enforces facility isolation and queries',
      () async {
        // site_1 returns alerts
        final alertsSite1 = await alertRepo.getAlerts(siteId: 'site_1');
        expect(alertsSite1.length, 2);

        // site_2 returns empty list
        final alertsSite2 = await alertRepo.getAlerts(siteId: 'site_2');
        expect(alertsSite2, isEmpty);

        // getAlertById
        final alert = await alertRepo.getAlertById('alert_evt_101');
        expect(alert.id, 'alert_evt_101');
        expect(alert.stationId, 'station_01');

        expect(
          () => alertRepo.getAlertById('unknown_id'),
          throwsA(isA<StateError>()),
        );

        // markAlertRead returns the alert without crashing
        final readAlert = await alertRepo.markAlertRead(
          alertId: 'alert_evt_101',
        );
        expect(readAlert.id, 'alert_evt_101');

        // mutations throw UnsupportedError
        expect(
          () => alertRepo.resolveAlert(
            alertId: 'alert_evt_101',
            resolvedByUserId: 'user_1',
          ),
          throwsA(isA<UnsupportedError>()),
        );
        expect(
          () => alertRepo.snoozeAlert(
            alertId: 'alert_evt_101',
            until: DateTime.now().add(const Duration(hours: 1)),
          ),
          throwsA(isA<UnsupportedError>()),
        );
      },
    );

    test(
      'RealtimeDashboardRepository builds correct data for site_1 and empty for other sites',
      () async {
        // Querying site_1
        final data = await dashboardRepo.getUserDashboard(
          user: testUser,
          siteId: 'site_1',
        );

        expect(data.stationMetrics.totalCount, 1);
        expect(data.stationMetrics.activeCount, 1);
        expect(data.stationMetrics.refillNeededCount, 0);
        expect(data.stationMetrics.offlineCount, 0);
        expect(data.detectionsToday, greaterThanOrEqualTo(1));
        expect(data.recentAlerts.length, 2);
        expect(data.mapMarkers.length, 1);
        expect(data.mapMarkers.first.stationId, 'station_01');

        // Querying site_2 returns empty dashboard data
        final emptyData = await dashboardRepo.getUserDashboard(
          user: testUser,
          siteId: 'site_2',
        );
        expect(emptyData.stationMetrics.totalCount, 0);
        expect(emptyData.recentAlerts, isEmpty);
        expect(emptyData.mapMarkers, isEmpty);
      },
    );

    test(
      'RealtimeReportRepository builds dashboard data for site_1 and empty for other sites',
      () async {
        final period = ReportPeriod(
          type: ReportPeriodType.month,
          anchorDate: DateTime.now(),
        );

        final reportsData = await reportRepo.getDashboardData(
          siteId: 'site_1',
          period: period,
        );

        expect(reportsData.summary.totalDetections, greaterThanOrEqualTo(1));
        expect(reportsData.stationLedger.length, 1);
        expect(reportsData.stationLedger.first.stationId, 'station_01');

        final emptyReports = await reportRepo.getDashboardData(
          siteId: 'site_2',
          period: period,
        );
        expect(emptyReports.summary.totalDetections, 0);
        expect(emptyReports.stationLedger, isEmpty);
      },
    );
  });
}
