import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/features/dashboard/view_models/user_dashboard_view_model.dart';
import 'package:baitguard/data/repositories/mock/mock_dashboard_repository.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/models/dashboard/user_dashboard_data.dart';

class SpyDashboardRepository extends MockDashboardRepository {
  int getUserDashboardCallCount = 0;
  bool shouldThrowError = false;

  SpyDashboardRepository(super.dataSource);

  @override
  Future<UserDashboardData> getUserDashboard({
    required AppUser user,
    String? siteId,
  }) async {
    getUserDashboardCallCount++;
    if (shouldThrowError) {
      throw Exception('Network error');
    }
    return super.getUserDashboard(user: user, siteId: siteId);
  }
}

void main() {
  group('UserDashboardViewModel', () {
    late MockBaitGuardDataSource dataSource;
    late SpyDashboardRepository dashboardRepository;
    late AppSessionController sessionController;

    setUp(() {
      dataSource = MockBaitGuardDataSource.seeded();
      dashboardRepository = SpyDashboardRepository(dataSource);
      sessionController = AppSessionController();
    });

    test('loads using the current authenticated viewer ID', () async {
      final viewer = dataSource.users.firstWhere(
        (u) => u.role == UserRole.viewer,
      );
      sessionController.establishSession(viewer);

      final viewModel = UserDashboardViewModel(
        dashboardRepository: dashboardRepository,
        sessionController: sessionController,
      );

      expect(viewModel.status, DashboardLoadStatus.initial);

      final loadFuture = viewModel.load();
      expect(viewModel.status, DashboardLoadStatus.loading);

      await loadFuture;

      expect(viewModel.status, DashboardLoadStatus.success);
      expect(viewModel.data, isNotNull);
      expect(viewModel.data!.user.id, viewer.id);
    });

    test('loads using the current authenticated technician ID', () async {
      final tech = dataSource.users.firstWhere(
        (u) => u.role == UserRole.technician,
      );
      sessionController.establishSession(tech);

      final viewModel = UserDashboardViewModel(
        dashboardRepository: dashboardRepository,
        sessionController: sessionController,
      );

      await viewModel.load();

      expect(viewModel.status, DashboardLoadStatus.success);
      expect(viewModel.data, isNotNull);
      expect(viewModel.data!.user.id, tech.id);
    });

    test('rejects or safely handles a missing session', () async {
      // Session is intentionally not set
      final viewModel = UserDashboardViewModel(
        dashboardRepository: dashboardRepository,
        sessionController: sessionController,
      );

      await viewModel.load();

      expect(viewModel.status, DashboardLoadStatus.failure);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.data, isNull);
    });

    test('rejects or safely handles admin role usage', () async {
      final admin = dataSource.users.firstWhere(
        (u) => u.role == UserRole.admin,
      );
      sessionController.establishSession(admin);

      final viewModel = UserDashboardViewModel(
        dashboardRepository: dashboardRepository,
        sessionController: sessionController,
      );

      await viewModel.load();

      expect(viewModel.status, DashboardLoadStatus.failure);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.data, isNull);
    });

    test('duplicate initial loads are prevented', () {
      final viewer = dataSource.users.firstWhere(
        (u) => u.role == UserRole.viewer,
      );
      sessionController.establishSession(viewer);

      final viewModel = UserDashboardViewModel(
        dashboardRepository: dashboardRepository,
        sessionController: sessionController,
      );

      viewModel.load();
      final statusAfterFirstLoad = viewModel.status;

      // Should not throw or change status abruptly during a concurrent load
      viewModel.load();
      expect(viewModel.status, statusAfterFirstLoad);
    });

    test('refresh preserves existing data', () async {
      final viewer = dataSource.users.firstWhere(
        (u) => u.role == UserRole.viewer,
      );
      sessionController.establishSession(viewer);

      final viewModel = UserDashboardViewModel(
        dashboardRepository: dashboardRepository,
        sessionController: sessionController,
      );

      await viewModel.load();
      expect(viewModel.status, DashboardLoadStatus.success);
      final initialData = viewModel.data;

      final refreshFuture = viewModel.refresh();
      // Data should still be present while refreshing
      expect(viewModel.data, initialData);
      expect(
        viewModel.status,
        DashboardLoadStatus.success,
      ); // status stays success

      await refreshFuture;
      expect(viewModel.data, isNotNull); // New data arrived
    });

    test('dashboard lists are immutable', () async {
      final viewer = dataSource.users.firstWhere(
        (u) => u.role == UserRole.viewer,
      );
      sessionController.establishSession(viewer);

      final viewModel = UserDashboardViewModel(
        dashboardRepository: dashboardRepository,
        sessionController: sessionController,
      );

      await viewModel.load();
      final data = viewModel.data!;

      expect(
        () => data.speciesBreakdown.add(data.speciesBreakdown.first),
        throwsUnsupportedError,
      );
      expect(
        () => data.activitySeries.add(data.activitySeries.first),
        throwsUnsupportedError,
      );
      expect(
        () => data.mapMarkers.add(data.mapMarkers.first),
        throwsUnsupportedError,
      );
      expect(
        () => data.recentAlerts.add(data.recentAlerts.first),
        throwsUnsupportedError,
      );
    });

    test(
      'refresh calls DashboardRepository again and duplicate refresh blocked',
      () async {
        final viewer = dataSource.users.firstWhere(
          (u) => u.role == UserRole.viewer,
        );
        sessionController.establishSession(viewer);
        final viewModel = UserDashboardViewModel(
          dashboardRepository: dashboardRepository,
          sessionController: sessionController,
        );

        await viewModel.load();
        expect(dashboardRepository.getUserDashboardCallCount, 1);

        // Call refresh multiple times concurrently
        final r1 = viewModel.refresh();
        final r2 = viewModel.refresh();

        await r1;
        await r2;

        // Should only call repo once during concurrent refresh
        expect(dashboardRepository.getUserDashboardCallCount, 2);
      },
    );

    test('refresh failure preserves data and exposes error once', () async {
      final viewer = dataSource.users.firstWhere(
        (u) => u.role == UserRole.viewer,
      );
      sessionController.establishSession(viewer);
      final viewModel = UserDashboardViewModel(
        dashboardRepository: dashboardRepository,
        sessionController: sessionController,
      );

      await viewModel.load();
      final dataBefore = viewModel.data;

      dashboardRepository.shouldThrowError = true;
      await viewModel.refresh();

      // Data is preserved
      expect(viewModel.data, dataBefore);
      expect(viewModel.status, DashboardLoadStatus.success);

      // Error event is exposed
      expect(
        viewModel.refreshErrorMessage,
        'Failed to refresh dashboard. Please try again.',
      );
      final eventId = viewModel.refreshErrorEventId;
      expect(eventId, greaterThan(0));

      // Error event is consumed once (the id doesn't change unless new error happens, so the UI consumes it by tracking id)
      // If we trigger another failure, the ID increments
      await viewModel.refresh();
      expect(viewModel.refreshErrorEventId, greaterThan(eventId));
    });
  });
}
