import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/data/repositories/mock/mock_dashboard_repository.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/features/dashboard/view_models/admin_dashboard_view_model.dart';
import 'package:baitguard/features/dashboard/view_models/user_dashboard_view_model.dart';
import 'package:baitguard/domain/models/dashboard/admin_dashboard_data.dart';
import 'package:baitguard/domain/models/app_user.dart';

class _FailingDashboardRepository extends MockDashboardRepository {
  _FailingDashboardRepository(super.dataSource);

  @override
  Future<AdminDashboardData> getAdminDashboard({
    required AppUser admin,
    String? siteId,
  }) async {
    throw Exception('Network error');
  }
}

void main() {
  late MockBaitGuardDataSource dataSource;
  late AppSessionController sessionController;
  late ActiveFacilityController facilityController;

  setUp(() {
    dataSource = MockBaitGuardDataSource.seeded();
    sessionController = AppSessionController();

    final admin = dataSource.users.firstWhere((u) => u.role == UserRole.admin);
    sessionController.establishSession(admin);

    facilityController = ActiveFacilityController(
      permittedSiteIds: admin.siteAccessIds,
    );
  });

  group('AdminDashboardViewModel – Active Facility Migration', () {
    test('6. Initial load uses controller selected site ID', () async {
      final repo = MockDashboardRepository(dataSource);
      final vm = AdminDashboardViewModel(
        dashboardRepository: repo,
        sessionController: sessionController,
        activeFacilityController: facilityController,
      );

      await vm.load();

      expect(vm.status, DashboardLoadStatus.success);
      expect(vm.data, isNotNull);
      // The loaded site should match the controller's selected site
      expect(vm.data!.selectedSite.id, facilityController.selectedSiteId);
    });

    test('7. Successful facility change commits the controller', () async {
      final repo = MockDashboardRepository(dataSource);
      final vm = AdminDashboardViewModel(
        dashboardRepository: repo,
        sessionController: sessionController,
        activeFacilityController: facilityController,
      );

      await vm.load();
      expect(facilityController.selectedSiteId, 'site_1');

      await vm.selectFacility('site_2');

      expect(vm.status, DashboardLoadStatus.success);
      expect(facilityController.selectedSiteId, 'site_2');
      expect(vm.data!.selectedSite.id, 'site_2');
    });

    test('8. Failed facility change does NOT change the controller', () async {
      final failRepo = _FailingDashboardRepository(dataSource);

      // Load with a working repo first to get initial data
      final workingRepo = MockDashboardRepository(dataSource);
      final vmWorking = AdminDashboardViewModel(
        dashboardRepository: workingRepo,
        sessionController: sessionController,
        activeFacilityController: facilityController,
      );
      await vmWorking.load();
      expect(facilityController.selectedSiteId, 'site_1');

      // Now try to switch with a failing repo
      final vm2 = AdminDashboardViewModel(
        dashboardRepository: failRepo,
        sessionController: sessionController,
        activeFacilityController: facilityController,
      );
      await vm2.load(); // This will fail but we need a previous state
      // selectFacility should fail
      await vm2.selectFacility('site_2');

      // Controller should remain on site_1
      expect(facilityController.selectedSiteId, 'site_1');
    });

    test('9. Admin Dashboard selectedSite is from availableSites', () async {
      final repo = MockDashboardRepository(dataSource);
      final vm = AdminDashboardViewModel(
        dashboardRepository: repo,
        sessionController: sessionController,
        activeFacilityController: facilityController,
      );

      await vm.load();

      final data = vm.data!;
      // selectedSite should be the same object reference as in availableSites
      // to avoid the Site-equality dropdown crash.
      final matchingSite = data.availableSites.firstWhere(
        (s) => s.id == data.selectedSite.id,
        orElse: () => throw StateError('selectedSite not in availableSites'),
      );
      expect(matchingSite.id, data.selectedSite.id);
      expect(matchingSite.name, data.selectedSite.name);
    });

    test('10. Same-site selectFacility is ignored', () async {
      final repo = MockDashboardRepository(dataSource);
      int notifyCount = 0;
      final vm = AdminDashboardViewModel(
        dashboardRepository: repo,
        sessionController: sessionController,
        activeFacilityController: facilityController,
      );
      vm.addListener(() => notifyCount++);

      await vm.load();
      notifyCount = 0; // Reset after initial load

      // Same site — should be a no-op
      await vm.selectFacility(facilityController.selectedSiteId!);
      expect(notifyCount, 0);
    });
  });
}
