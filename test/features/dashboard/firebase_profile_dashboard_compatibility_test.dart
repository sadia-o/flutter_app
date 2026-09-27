import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/data/repositories/mock/mock_dashboard_repository.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/dashboard/admin_dashboard_data.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/models/access_request.dart';
import 'package:baitguard/domain/models/access_request_record.dart';
import 'package:baitguard/domain/models/access_request_failure.dart';
import 'package:baitguard/domain/repositories/access_request_repository.dart';
import 'package:baitguard/features/dashboard/view_models/admin_dashboard_view_model.dart';
import 'package:baitguard/features/dashboard/view_models/user_dashboard_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailOnceDashboardRepository extends MockDashboardRepository {
  _FailOnceDashboardRepository(super.dataSource);

  bool _shouldFail = true;
  int calls = 0;

  @override
  Future<AdminDashboardData> getAdminDashboard({
    required AppUser admin,
    String? siteId,
  }) {
    calls++;
    if (_shouldFail) {
      _shouldFail = false;
      throw StateError('Temporary test failure');
    }
    return super.getAdminDashboard(admin: admin, siteId: siteId);
  }
}

class _PendingRepositoryFake implements AccessRequestRepository {
  _PendingRepositoryFake(this.records);

  List<AccessRequestRecord> records;
  AccessRequestFailure? failure;

  @override
  Future<List<AccessRequestRecord>> getPendingRequests({String? siteId}) async {
    if (failure != null) throw failure!;
    return records;
  }

  @override
  Future<void> submitRequest(AccessRequest request) =>
      throw UnsupportedError('Not used');

  @override
  Future<void> approveRequest({
    required String requestId,
    required String reviewerUid,
    required UserRole assignedRole,
    required List<String> assignedFacilityIds,
  }) => throw UnsupportedError('Not used');

  @override
  Future<void> rejectRequest({
    required String requestId,
    required String reviewerUid,
    required String rejectionReason,
  }) => throw UnsupportedError('Not used');
}

AccessRequestRecord _pending(String id, DateTime submittedAt) {
  final request = AccessRequest(
    requestId: id,
    fullName: 'Applicant $id',
    email: '$id@example.com',
    company: 'Trinode',
    phone: '+123456789',
    submittedAt: submittedAt,
  );
  return AccessRequestRecord(
    id: id,
    request: request,
    status: AccessRequestStatus.pending,
  );
}

AppUser _firebaseUser({
  required String id,
  required String name,
  required UserRole role,
  required List<String> facilityIds,
}) {
  return AppUser(
    id: id,
    name: name,
    email: '$id@example.com',
    role: role,
    siteAccessIds: facilityIds,
  );
}

void main() {
  late MockBaitGuardDataSource dataSource;

  setUp(() {
    dataSource = MockBaitGuardDataSource.seeded();
  });

  test('Firebase UID absent from seeded users loads admin mock data', () async {
    final admin = _firebaseUser(
      id: 'MB4ejIAAN1ff3V2I4R8NqSE6Kov2',
      name: 'Taha Fayyaz',
      role: UserRole.admin,
      facilityIds: const ['site_1', 'site_2'],
    );
    final session = AppSessionController()..establishSession(admin);
    final facility = ActiveFacilityController(
      permittedSiteIds: admin.siteAccessIds,
    );
    final viewModel = AdminDashboardViewModel(
      dashboardRepository: MockDashboardRepository(dataSource),
      sessionController: session,
      activeFacilityController: facility,
    );

    await viewModel.load();

    expect(viewModel.status, DashboardLoadStatus.success);
    expect(viewModel.adminUser, same(admin));
    expect(viewModel.adminUser.name, 'Taha Fayyaz');
    expect(
      viewModel.data!.availableSites.map((site) => site.id),
      orderedEquals(['site_1', 'site_2']),
    );
    expect(
      viewModel.data!.stationMetrics,
      dataSource.deploymentSnapshot.stationMetrics,
    );
  });

  test(
    'admin dashboard replaces only pending counts with repository data',
    () async {
      final now = DateTime.now();
      final admin = _firebaseUser(
        id: 'firebase-admin',
        name: 'Real Admin',
        role: UserRole.admin,
        facilityIds: const ['site_1'],
      );
      final viewModel = AdminDashboardViewModel(
        dashboardRepository: MockDashboardRepository(dataSource),
        accessRequestRepository: _PendingRepositoryFake([
          _pending('today', now),
          _pending('older', now.subtract(const Duration(days: 3))),
        ]),
        sessionController: AppSessionController()..establishSession(admin),
        activeFacilityController: ActiveFacilityController(
          permittedSiteIds: admin.siteAccessIds,
        ),
      );

      await viewModel.load();

      expect(viewModel.data!.pendingRequestCount, 2);
      expect(viewModel.data!.newPendingRequestCountToday, 1);
      expect(
        viewModel.data!.stationMetrics,
        dataSource.deploymentSnapshot.stationMetrics,
      );
      expect(viewModel.data!.userCount, 28);
    },
  );

  test(
    'successful empty pending query produces zero without an error event',
    () async {
      final admin = _firebaseUser(
        id: 'firebase-admin',
        name: 'Real Admin',
        role: UserRole.admin,
        facilityIds: const ['site_1'],
      );
      final viewModel = AdminDashboardViewModel(
        dashboardRepository: MockDashboardRepository(dataSource),
        accessRequestRepository: _PendingRepositoryFake([]),
        sessionController: AppSessionController()..establishSession(admin),
        activeFacilityController: ActiveFacilityController(
          permittedSiteIds: admin.siteAccessIds,
        ),
      );

      await viewModel.load();

      expect(viewModel.status, DashboardLoadStatus.success);
      expect(viewModel.data!.pendingRequestCount, 0);
      expect(viewModel.data!.newPendingRequestCountToday, 0);
      expect(viewModel.refreshErrorEventId, 0);
      expect(viewModel.refreshErrorMessage, isNull);
    },
  );

  test(
    'dashboard pending failures retain typed messages and prior count',
    () async {
      final expected = {
        AccessRequestFailureType.missingIndex:
            'Pending requests are temporarily unavailable while database setup is completed.',
        AccessRequestFailureType.unavailable:
            'Unable to load pending requests. Check your connection and try again.',
        AccessRequestFailureType.permissionDenied:
            'You do not have permission to review access requests.',
      };
      for (final entry in expected.entries) {
        final admin = _firebaseUser(
          id: 'firebase-admin',
          name: 'Real Admin',
          role: UserRole.admin,
          facilityIds: const ['site_1'],
        );
        final pendingRepository = _PendingRepositoryFake([
          _pending('existing', DateTime.now()),
        ]);
        final viewModel = AdminDashboardViewModel(
          dashboardRepository: MockDashboardRepository(dataSource),
          accessRequestRepository: pendingRepository,
          sessionController: AppSessionController()..establishSession(admin),
          activeFacilityController: ActiveFacilityController(
            permittedSiteIds: admin.siteAccessIds,
          ),
        );
        await viewModel.load();
        pendingRepository.failure = AccessRequestFailure(entry.key);

        await viewModel.refresh();

        expect(viewModel.data!.pendingRequestCount, 1);
        expect(viewModel.refreshErrorMessage, entry.value);
      }
    },
  );

  test(
    'unauthorized and invalid seeded facilities are never granted',
    () async {
      final admin = _firebaseUser(
        id: 'firebase-admin',
        name: 'Real Admin',
        role: UserRole.admin,
        facilityIds: const ['missing_site', 'site_3'],
      );

      final data = await MockDashboardRepository(
        dataSource,
      ).getAdminDashboard(admin: admin, siteId: 'missing_site');

      expect(data.availableSites.map((site) => site.id), ['site_3']);
      expect(data.selectedSite.id, 'site_3');
      expect(data.availableSites.any((site) => site.id == 'site_1'), isFalse);
    },
  );

  test('empty and entirely invalid facility permissions fail safely', () async {
    final repository = MockDashboardRepository(dataSource);
    final emptyAdmin = _firebaseUser(
      id: 'empty-admin',
      name: 'Empty Admin',
      role: UserRole.admin,
      facilityIds: const [],
    );
    final invalidAdmin = _firebaseUser(
      id: 'invalid-admin',
      name: 'Invalid Admin',
      role: UserRole.admin,
      facilityIds: const ['not_seeded'],
    );

    expect(
      () => repository.getAdminDashboard(admin: emptyAdmin),
      throwsA(isA<Exception>()),
    );
    expect(
      () => repository.getAdminDashboard(admin: invalidAdmin),
      throwsA(isA<Exception>()),
    );
  });

  for (final role in [UserRole.technician, UserRole.viewer]) {
    test(
      'Firebase ${role.name} UID loads without a seeded user fallback',
      () async {
        final user = _firebaseUser(
          id: 'firebase-${role.name}',
          name: 'Firestore ${role.name}',
          role: role,
          facilityIds: const ['site_1'],
        );

        final data = await MockDashboardRepository(
          dataSource,
        ).getUserDashboard(user: user, siteId: 'site_1');

        expect(data.user, same(user));
        expect(data.user.name, 'Firestore ${role.name}');
        expect(
          data.mapMarkers.every((marker) {
            final station = dataSource.stations.firstWhere(
              (candidate) => candidate.id == marker.stationId,
            );
            return station.siteId == 'site_1';
          }),
          isTrue,
        );
      },
    );
  }

  test('Retry succeeds when the repository succeeds', () async {
    final admin = _firebaseUser(
      id: 'firebase-admin',
      name: 'Taha Fayyaz',
      role: UserRole.admin,
      facilityIds: const ['site_1'],
    );
    final repository = _FailOnceDashboardRepository(dataSource);
    final viewModel = AdminDashboardViewModel(
      dashboardRepository: repository,
      sessionController: AppSessionController()..establishSession(admin),
      activeFacilityController: ActiveFacilityController(
        permittedSiteIds: admin.siteAccessIds,
      ),
    );

    await viewModel.load();
    expect(viewModel.status, DashboardLoadStatus.failure);

    await viewModel.load();

    expect(viewModel.status, DashboardLoadStatus.success);
    expect(repository.calls, 2);
  });
}
