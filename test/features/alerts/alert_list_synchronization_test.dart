import 'package:flutter_test/flutter_test.dart';

import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/features/alerts/view_models/alerts_view_model.dart';
import 'package:baitguard/features/alerts/view_models/alert_detail_view_model.dart';

import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/data/repositories/mock/mock_alert_repository.dart';
import 'package:baitguard/data/repositories/mock/mock_station_repository.dart';

void main() {
  group('Alert List Synchronization', () {
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

      final adminUser = dataSource.users.firstWhere(
        (u) => u.role == UserRole.admin,
      );
      sessionController.establishSession(adminUser);
      activeFacilityController = ActiveFacilityController(
        permittedSiteIds: adminUser.siteAccessIds,
        initialSiteId: adminUser.siteAccessIds.first,
      );
    });

    test('AlertsViewModel applies update and recomputes counts', () async {
      final vm = AlertsViewModel(
        alertRepository: alertRepository,
        stationRepository: stationRepository,
        sessionController: sessionController,
        activeFacilityController: activeFacilityController,
      );

      // Wait for load
      await vm.refresh();

      final initialUnresolved = vm.unresolvedCount;
      expect(initialUnresolved, greaterThan(0));

      final detailVm = AlertDetailViewModel(
        alertId: 'alert_1',
        alertRepository: alertRepository,
        stationRepository: stationRepository,
        sessionController: sessionController,
        activeFacilityController: activeFacilityController,
      );

      // await initialization
      await Future.delayed(const Duration(milliseconds: 300));

      await detailVm.resolveAlert();
      expect(detailVm.lastUpdatedAlert, isNotNull);

      vm.applyUpdatedAlert(detailVm.lastUpdatedAlert!);

      expect(vm.unresolvedCount, initialUnresolved - 1);
    });
  });
}
