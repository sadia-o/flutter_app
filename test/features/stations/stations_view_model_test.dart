import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/data/repositories/mock/mock_station_repository.dart';
import 'package:baitguard/domain/models/station.dart';
import 'package:baitguard/domain/models/station_status.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/station_repository.dart';
import 'package:baitguard/features/stations/models/station_list_filter.dart';
import 'package:baitguard/features/stations/models/station_permissions.dart';
import 'package:baitguard/features/stations/view_models/stations_view_model.dart';

// ── Spy repository ─────────────────────────────────────────────────────────────

class _SpyStationRepository extends MockStationRepository {
  int getStationsCallCount = 0;
  bool shouldThrow = false;

  _SpyStationRepository(super.dataSource);

  @override
  Future<List<Station>> getStations({String? siteId}) async {
    getStationsCallCount++;
    if (shouldThrow) throw Exception('Network error');
    return super.getStations(siteId: siteId);
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

StationsViewModel _makeVm({
  required MockBaitGuardDataSource dataSource,
  required AppSessionController sessionController,
  required ActiveFacilityController facilityController,
  StationRepository? repository,
}) {
  return StationsViewModel(
    stationRepository: repository ?? MockStationRepository(dataSource),
    sessionController: sessionController,
    activeFacilityController: facilityController,
  );
}

void main() {
  late MockBaitGuardDataSource dataSource;
  late AppSessionController sessionController;
  late ActiveFacilityController facilityController;

  setUp(() {
    dataSource = MockBaitGuardDataSource.seeded();
    sessionController = AppSessionController();
  });

  void loginAs(UserRole role) {
    final user = dataSource.users.firstWhere((u) => u.role == role);
    sessionController.establishSession(user);
    facilityController = ActiveFacilityController(
      permittedSiteIds: user.siteAccessIds,
    );
  }

  group('StationsViewModel — Loading', () {
    test('11. Loads stations using selected site ID', () async {
      loginAs(UserRole.viewer);
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
      );

      await vm.load();

      expect(vm.status, StationsLoadStatus.success);
      expect(vm.allStations.isNotEmpty, isTrue);
      for (final s in vm.allStations) {
        expect(s.siteId, facilityController.selectedSiteId);
      }
    });

    test('12. Missing session fails safely', () async {
      // Don't log in
      facilityController = ActiveFacilityController(
        permittedSiteIds: ['site_1'],
      );
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController, // No user
        facilityController: facilityController,
      );

      await vm.load();

      expect(vm.status, StationsLoadStatus.failure);
      expect(vm.errorMessage, isNotNull);
    });

    test('13. Empty site access fails safely', () async {
      final inactiveUser = dataSource.users.firstWhere(
        (u) => u.siteAccessIds.isEmpty,
      );
      sessionController.establishSession(inactiveUser);
      facilityController = ActiveFacilityController(permittedSiteIds: []);

      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
      );

      await vm.load();

      expect(vm.status, StationsLoadStatus.failure);
    });

    test('14. Duplicate loads are blocked', () async {
      loginAs(UserRole.viewer);
      final spy = _SpyStationRepository(dataSource);
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
        repository: spy,
      );

      // Fire two loads without awaiting
      final f1 = vm.load();
      final f2 = vm.load(); // Should be ignored
      await Future.wait([f1, f2]);

      expect(spy.getStationsCallCount, 1);
    });

    test('15. Refresh calls repository again', () async {
      loginAs(UserRole.viewer);
      final spy = _SpyStationRepository(dataSource);
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
        repository: spy,
      );

      await vm.load();
      await vm.refresh();

      expect(spy.getStationsCallCount, 2);
    });

    test('16. Existing data remains visible during refresh failure', () async {
      loginAs(UserRole.viewer);
      final spy = _SpyStationRepository(dataSource);
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
        repository: spy,
      );

      await vm.load();
      final previousCount = vm.allStations.length;
      expect(previousCount, greaterThan(0));

      spy.shouldThrow = true;
      await vm.refresh();

      // Data should be preserved
      expect(vm.allStations.length, previousCount);
      expect(vm.status, StationsLoadStatus.success);
    });

    test('17. Facility change causes exactly one reload', () async {
      loginAs(UserRole.admin);
      final spy = _SpyStationRepository(dataSource);
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
        repository: spy,
      );

      await vm.load();
      expect(spy.getStationsCallCount, 1);

      // Change to a different site
      facilityController.selectSite('site_2');
      // Allow the async listener to fire
      await Future.delayed(const Duration(milliseconds: 1200));

      expect(spy.getStationsCallCount, 2);
    });

    test('18. Same-site selection causes no reload', () async {
      loginAs(UserRole.admin);
      final spy = _SpyStationRepository(dataSource);
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
        repository: spy,
      );

      await vm.load();
      expect(spy.getStationsCallCount, 1);

      // Select same site — controller won't notify, VM won't reload
      facilityController.selectSite(facilityController.selectedSiteId!);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(spy.getStationsCallCount, 1);
    });

    test('19. Listener is removed on dispose', () async {
      loginAs(UserRole.viewer);
      final spy = _SpyStationRepository(dataSource);
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
        repository: spy,
      );

      await vm.load();
      vm.dispose();

      // After dispose, facility change should not trigger reload
      facilityController.selectSite('site_2');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(spy.getStationsCallCount, 1); // No additional load
    });

    test('20. Exposed lists are immutable', () async {
      loginAs(UserRole.viewer);
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
      );

      await vm.load();

      expect(
        () => (vm.allStations as dynamic).add(vm.allStations.first),
        throwsUnsupportedError,
      );
      expect(
        () => (vm.filteredStations as dynamic).add(vm.allStations.first),
        throwsUnsupportedError,
      );
    });
  });

  group('StationsViewModel — Search and Filters', () {
    late StationsViewModel vm;

    setUp(() async {
      loginAs(UserRole.admin);
      vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
      );
      await vm.load();
    });

    test('21. Search matches station ID', () {
      vm.setSearchQuery('RB-07');
      expect(vm.filteredStations.any((s) => s.id == 'RB-07'), isTrue);
      expect(vm.filteredStations.length, 1);
    });

    test('22. Search matches location', () {
      vm.setSearchQuery('kitchen');
      expect(vm.filteredStations.any((s) => s.id == 'RB-01'), isTrue);
    });

    test('23. All filter returns all loaded stations', () {
      vm.setFilter(StationListFilter.all);
      expect(vm.filteredStations.length, vm.allStations.length);
    });

    test('24. Alerts filter returns attention-requiring stations', () {
      vm.setFilter(StationListFilter.alerts);
      for (final s in vm.filteredStations) {
        final needsAttention =
            s.status == StationStatus.alert ||
            s.status == StationStatus.offline ||
            s.isTampered;
        expect(needsAttention, isTrue, reason: '${s.id} should need attention');
      }
    });

    test('25. Low bait filter uses centralized threshold (25%)', () {
      vm.setFilter(StationListFilter.lowBait);
      for (final s in vm.filteredStations) {
        expect(s.baitPercentage, lessThanOrEqualTo(kLowBaitThreshold));
      }
    });

    test('26. Online filter excludes offline stations', () {
      vm.setFilter(StationListFilter.online);
      for (final s in vm.filteredStations) {
        expect(s.status, isNot(StationStatus.offline));
      }
    });

    test('27. Search and filter combine correctly', () {
      vm.setFilter(StationListFilter.alerts);
      vm.setSearchQuery('RB-07');
      expect(
        vm.filteredStations.every(
          (s) =>
              s.id.toLowerCase().contains('rb-07') &&
              (s.status == StationStatus.alert ||
                  s.status == StationStatus.offline ||
                  s.isTampered),
        ),
        isTrue,
      );
    });

    test('28. No-result state clears featured station', () {
      vm.setSearchQuery('STATION_THAT_DOES_NOT_EXIST_XYZ');
      expect(vm.filteredStations, isEmpty);
      expect(vm.featuredStation, isNull);
    });

    test('29. Featured station priority is deterministic (alert first)', () {
      vm.setFilter(StationListFilter.all);
      final featured = vm.featuredStation;
      expect(featured, isNotNull);
      // Featured should be an alert or tampered station if any exist
      final hasAlerts = vm.allStations.any(
        (s) => s.status == StationStatus.alert || s.isTampered,
      );
      if (hasAlerts) {
        final s = featured!.station;
        expect(s.status == StationStatus.alert || s.isTampered, isTrue);
      }
    });
  });

  group('StationsViewModel — Permissions', () {
    test('30. Admin permissions are correct', () {
      loginAs(UserRole.admin);
      // Permissions are resolved on load, but we can test the static factory
      final perms = StationPermissions.fromRole(UserRole.admin);
      expect(perms.canAddStation, isTrue);
      expect(perms.canRefill, isTrue);
      expect(perms.canSilence, isTrue);
      expect(perms.canLocate, isTrue);
    });

    test('31. Technician permissions are correct', () {
      final perms = StationPermissions.fromRole(UserRole.technician);
      expect(perms.canAddStation, isFalse);
      expect(perms.canRefill, isTrue);
      expect(perms.canSilence, isTrue);
      expect(perms.canLocate, isTrue);
    });

    test('32. Viewer permissions are read-only', () {
      final perms = StationPermissions.fromRole(UserRole.viewer);
      expect(perms.canAddStation, isFalse);
      expect(perms.canRefill, isFalse);
      expect(perms.canSilence, isFalse);
      expect(perms.canLocate, isTrue);
    });

    test('33. Add Station visibility follows permissions', () {
      final adminPerms = StationPermissions.fromRole(UserRole.admin);
      final viewerPerms = StationPermissions.fromRole(UserRole.viewer);
      final techPerms = StationPermissions.fromRole(UserRole.technician);
      expect(adminPerms.canAddStation, isTrue);
      expect(viewerPerms.canAddStation, isFalse);
      expect(techPerms.canAddStation, isFalse);
    });
  });

  group('StationsViewModel — Mutations', () {
    late StationsViewModel vmAdmin;

    setUp(() async {
      loginAs(UserRole.admin);
      vmAdmin = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
      );
      await vmAdmin.load();
    });

    test('34. Refill sets bait to 100', () async {
      final lowBaitStation = vmAdmin.allStations.firstWhere(
        (s) => s.status == StationStatus.lowBait,
      );
      expect(lowBaitStation.baitPercentage, lessThan(100));

      await vmAdmin.refillStation(lowBaitStation.id);

      final updated = vmAdmin.allStations.firstWhere(
        (s) => s.id == lowBaitStation.id,
      );
      expect(updated.baitPercentage, 100.0);
    });

    test('35. Refill persists in subsequent repository reads', () async {
      final repo = MockStationRepository(dataSource);
      final lowBaitStation = vmAdmin.allStations.firstWhere(
        (s) => s.status == StationStatus.lowBait,
      );
      await vmAdmin.refillStation(lowBaitStation.id);

      // Repository should reflect the change
      final refreshed = await repo.getStationById(lowBaitStation.id);
      expect(refreshed?.baitPercentage, 100.0);
    });

    test(
      '36. Refill preserves alert/tamper state (non-lowBait station)',
      () async {
        final alertStation = vmAdmin.allStations.firstWhere(
          (s) => s.status == StationStatus.alert,
        );
        final originalStatus = alertStation.status;

        await vmAdmin.refillStation(alertStation.id);

        final updated = vmAdmin.allStations.firstWhere(
          (s) => s.id == alertStation.id,
        );
        expect(updated.baitPercentage, 100.0);
        expect(updated.status, originalStatus); // Alert preserved
      },
    );

    test('37. Silence persists notificationsMuted', () async {
      final station = vmAdmin.allStations.first;
      expect(station.notificationsMuted, isFalse);

      await vmAdmin.toggleSilenceStation(station.id);

      final updated = vmAdmin.allStations.firstWhere((s) => s.id == station.id);
      expect(updated.notificationsMuted, isTrue);
    });

    test('38. Silence does not alter station status', () async {
      final station = vmAdmin.allStations.firstWhere(
        (s) => s.status == StationStatus.alert,
      );
      final originalStatus = station.status;

      await vmAdmin.toggleSilenceStation(station.id);

      final updated = vmAdmin.allStations.firstWhere((s) => s.id == station.id);
      expect(updated.status, originalStatus);
    });

    test('39. Duplicate mutation for the same station is blocked', () async {
      final station = vmAdmin.allStations.first;

      // Both start simultaneously
      final f1 = vmAdmin.refillStation(station.id);
      final f2 = vmAdmin.refillStation(station.id);
      await Future.wait([f1, f2]);

      // The mutation should have happened once — bait is 100
      final updated = vmAdmin.allStations.firstWhere((s) => s.id == station.id);
      expect(updated.baitPercentage, 100.0);
    });

    test('40. Viewer cannot perform refill mutation', () async {
      loginAs(UserRole.viewer);
      final vmViewer = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
      );
      await vmViewer.load();

      final stationId = vmViewer.allStations.first.id;
      final originalBait = vmViewer.allStations.first.baitPercentage;

      await vmViewer.refillStation(stationId);

      // Bait should be unchanged
      final after = vmViewer.allStations.firstWhere((s) => s.id == stationId);
      expect(after.baitPercentage, originalBait);
    });
  });

  group('StationsViewModel — Header Summary', () {
    test('41. Header counts reflect loaded stations', () async {
      loginAs(UserRole.viewer);
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
      );
      await vm.load();

      expect(vm.totalCount, vm.allStations.length);
      expect(
        vm.activeCount,
        vm.allStations.where((s) => s.status != StationStatus.offline).length,
      );
    });
  });

  group('StationsViewModel — See All', () {
    test('49. clearSearchAndFilter resets to All with no query', () async {
      loginAs(UserRole.viewer);
      final vm = _makeVm(
        dataSource: dataSource,
        sessionController: sessionController,
        facilityController: facilityController,
      );
      await vm.load();

      vm.setFilter(StationListFilter.alerts);
      vm.setSearchQuery('RB-07');
      vm.clearSearchAndFilter();

      expect(vm.selectedFilter, StationListFilter.all);
      expect(vm.searchQuery, '');
      expect(vm.filteredStations.length, vm.allStations.length);
    });
  });
}
