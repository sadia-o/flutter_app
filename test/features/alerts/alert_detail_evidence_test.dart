import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/alert_type.dart';
import 'package:baitguard/domain/models/alert_status.dart';
import 'package:baitguard/domain/models/detected_species.dart';
import 'package:baitguard/domain/models/detection_event.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/features/alerts/view_models/alert_detail_view_model.dart';
import 'package:baitguard/features/alerts/views/alert_detail_screen.dart';

import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/data/repositories/mock/mock_alert_repository.dart';
import 'package:baitguard/data/repositories/mock/mock_station_repository.dart';
import 'package:baitguard/data/repositories/mock/mock_deployment_snapshot.dart';

void main() {
  group('Alert Detail Evidence Behavior', () {
    late MockBaitGuardDataSource dataSource;
    late MockAlertRepository alertRepository;
    late MockStationRepository stationRepository;
    late AppSessionController sessionController;
    late ActiveFacilityController activeFacilityController;

    setUp(() {
      dataSource = MockBaitGuardDataSource.seeded();
      alertRepository = MockAlertRepository(dataSource);
      stationRepository = MockStationRepository(dataSource);
      sessionController = AppSessionController();

      // Default to admin
      final adminUser = dataSource.users.firstWhere(
        (u) => u.role == UserRole.admin,
      );
      sessionController.establishSession(adminUser);
      activeFacilityController = ActiveFacilityController(
        permittedSiteIds: adminUser.siteAccessIds,
        initialSiteId: adminUser.siteAccessIds.first,
      );
    });

    Future<AlertDetailViewModel> createViewModel(String alertId) async {
      final vm = AlertDetailViewModel(
        alertId: alertId,
        alertRepository: alertRepository,
        stationRepository: stationRepository,
        sessionController: sessionController,
        activeFacilityController: activeFacilityController,
      );
      await Future.delayed(const Duration(milliseconds: 50));
      while (vm.isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return vm;
    }

    test(
      '1. Rodent alert with linked event and camera exposes evidence',
      () async {
        final vm = await createViewModel('alert_1');
        expect(vm.alert?.type, AlertType.rodent);
        expect(vm.station?.hasCamera, true);
        expect(vm.hasEvidence, true);
        expect(vm.linkedEvidenceEvent, isNotNull);
        expect(vm.linkedEvidenceEvent!.id, 'evt_rb07_1');
      },
    );

    test(
      '2. Rodent alert without linked event does not expose evidence',
      () async {
        final vm = await createViewModel('alert_5');
        expect(vm.alert?.type, AlertType.rodent);
        expect(vm.station?.hasCamera, true);
        expect(vm.hasEvidence, false);
        expect(vm.linkedEvidenceEvent, isNull);
      },
    );

    test(
      '3. Rodent alert on camera-less station does not expose evidence',
      () async {
        final vm = await createViewModel('alert_7');
        expect(vm.alert?.type, AlertType.rodent);
        expect(vm.station?.hasCamera, false);
        expect(vm.hasEvidence, false);
        expect(vm.linkedEvidenceEvent, isNull);
      },
    );

    test('4. Low-bait alert does not expose camera evidence', () async {
      final vm = await createViewModel('alert_2');
      expect(vm.alert?.type, AlertType.lowBait);
      expect(vm.hasEvidence, false);
    });

    test(
      '5. Tamper alert without linked camera event does not expose evidence',
      () async {
        final vm = await createViewModel('alert_3');
        expect(vm.alert?.type, AlertType.tamper);
        expect(vm.hasEvidence, false);
      },
    );

    test('6. Offline alert does not expose camera evidence', () async {
      final vm = await createViewModel('alert_4');
      expect(vm.alert?.type, AlertType.stationOffline);
      expect(vm.hasEvidence, false);
    });

    test('7. Resolved rodent alert retains linked evidence', () async {
      final vm = await createViewModel('alert_1');
      await vm.resolveAlert();
      expect(vm.alert?.status, AlertStatus.resolved);
      expect(vm.hasEvidence, true);
    });

    test('8. Dismissed rodent alert retains linked evidence', () async {
      final vm = await createViewModel('alert_1');
      await vm.dismissAlert();
      expect(vm.alert?.status, AlertStatus.dismissed);
      expect(vm.hasEvidence, true);
    });

    test('9. Snoozing does not remove evidence', () async {
      final vm = await createViewModel('alert_1');
      await vm.snoozeAlert(DateTime.now().add(const Duration(hours: 1)));
      expect(vm.alert?.snoozedUntil, isNotNull);
      expect(vm.hasEvidence, true);
    });

    test('10. Assigning does not remove evidence', () async {
      final vm = await createViewModel('alert_1');
      await vm.assignAlert('tech_1');
      expect(vm.alert?.assignedTechnicianId, isNotNull);
      expect(vm.hasEvidence, true);
    });

    test(
      '11. Alert.detectionEventId and DetectionEvent.alertId are coherent',
      () async {
        final alert = await alertRepository.getAlertById('alert_1');
        expect(alert.detectionEventId, 'evt_rb07_1');
        final event = dataSource.detectionEvents.firstWhere(
          (e) => e.id == 'evt_rb07_1',
        );
        expect(event.alertId, 'alert_1');
      },
    );

    test('12. Linked event belongs to the same station', () async {
      final vm = await createViewModel('alert_1');
      expect(vm.linkedEvidenceEvent!.stationId, vm.alert!.stationId);
    });

    test('13. Mismatched station event is rejected', () async {
      final events = dataSource.detectionEvents.toList();
      final index = events.indexWhere((e) => e.id == 'evt_rb07_1');
      events[index] = DetectionEvent(
        id: 'evt_rb07_1',
        stationId: 'RB-99',
        timestamp: DateTime.now(),
        species: DetectedSpecies.rat,
        confidenceScore: 0.96,
        alertId: 'alert_1',
      );

      final mockData = MockBaitGuardDataSource(
        deploymentSnapshot: MockDeploymentSnapshot.seeded(),
        sites: dataSource.sites,
        users: dataSource.users,
        stations: dataSource.stations,
        alerts: dataSource.alerts,
        accessRequests: dataSource.accessRequests,
        detectionEvents: events,
      );

      final vm = AlertDetailViewModel(
        alertId: 'alert_1',
        alertRepository: MockAlertRepository(mockData),
        stationRepository: MockStationRepository(mockData),
        sessionController: sessionController,
        activeFacilityController: activeFacilityController,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      while (vm.isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      expect(vm.hasEvidence, false);
    });

    testWidgets('14. Evidence image URL displays when available', (
      tester,
    ) async {
      final events = dataSource.detectionEvents.toList();
      final index = events.indexWhere((e) => e.id == 'evt_rb07_1');
      events[index] = DetectionEvent(
        id: 'evt_rb07_1',
        stationId: 'RB-07',
        timestamp: DateTime.now(),
        species: DetectedSpecies.rat,
        confidenceScore: 0.96,
        alertId: 'alert_1',
        evidenceImageUrl: 'assets/images/rodent_evidence.png',
      );

      final mockData = MockBaitGuardDataSource(
        deploymentSnapshot: MockDeploymentSnapshot.seeded(),
        sites: dataSource.sites,
        users: dataSource.users,
        stations: dataSource.stations,
        alerts: dataSource.alerts,
        accessRequests: dataSource.accessRequests,
        detectionEvents: events,
      );

      final vm = AlertDetailViewModel(
        alertId: 'alert_1',
        alertRepository: MockAlertRepository(mockData),
        stationRepository: MockStationRepository(mockData),
        sessionController: sessionController,
        activeFacilityController: activeFacilityController,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: vm,
            child: const AlertDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Swallow the expected AssetImage-not-found error —
      // assets are not bundled in the test environment.
      tester.takeException();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Evidence'), findsOneWidget);
      expect(find.text('Captured evidence is unavailable.'), findsNothing);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('15. Missing image URL shows unavailable-evidence state', (
      tester,
    ) async {
      final vm = (await tester.runAsync(() => createViewModel('alert_1')))!;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: vm,
            child: const AlertDetailScreen(),
          ),
        ),
      );

      await tester.pump(); // render first frame; no fake-clock advance

      expect(find.text('Evidence'), findsOneWidget);
      expect(find.text('Captured evidence is unavailable.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('16. Null evidence hides the entire section', (tester) async {
      final vm = (await tester.runAsync(() => createViewModel('alert_5')))!;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: vm,
            child: const AlertDetailScreen(),
          ),
        ),
      );

      await tester.pump(); // render first frame; no fake-clock advance

      expect(find.text('Evidence'), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
    });

    test('17. Viewer can view genuine evidence', () async {
      final user = dataSource.users.firstWhere(
        (u) => u.role == UserRole.viewer,
      );
      sessionController.establishSession(user);
      final vm = await createViewModel('alert_1');
      expect(vm.hasEvidence, true);
    });

    test('18. Technician can view genuine evidence', () async {
      final user = dataSource.users.firstWhere(
        (u) => u.role == UserRole.technician,
      );
      sessionController.establishSession(user);
      final vm = await createViewModel('alert_1');
      expect(vm.hasEvidence, true);
    });

    test('19. Admin can view genuine evidence', () async {
      final user = dataSource.users.firstWhere((u) => u.role == UserRole.admin);
      sessionController.establishSession(user);
      final vm = await createViewModel('alert_1');
      expect(vm.hasEvidence, true);
    });
  });
}
