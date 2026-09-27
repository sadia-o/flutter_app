import 'dart:async';

import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/data/repositories/mock/mock_settings_repository.dart';
import 'package:baitguard/domain/models/access_request.dart';
import 'package:baitguard/domain/models/access_request_failure.dart';
import 'package:baitguard/domain/models/access_request_record.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/access_request_repository.dart';
import 'package:baitguard/features/admin/view_models/pending_requests_view_model.dart';
import 'package:baitguard/features/admin/view_models/review_access_request_view_model.dart';
import 'package:baitguard/features/admin/views/approve_request_screen.dart';
import 'package:baitguard/features/admin/views/pending_requests_screen.dart';
import 'package:baitguard/app/navigation/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ReviewRepositoryFake implements AccessRequestRepository {
  int approveCalls = 0;
  int rejectCalls = 0;
  UserRole? role;
  List<String>? facilityIds;
  String? reason;
  Object? failure;
  Completer<void>? completer;

  @override
  Future<void> approveRequest({
    required String requestId,
    required String reviewerUid,
    required UserRole assignedRole,
    required List<String> assignedFacilityIds,
  }) async {
    approveCalls++;
    role = assignedRole;
    facilityIds = assignedFacilityIds;
    if (failure != null) throw failure!;
    if (completer != null) await completer!.future;
  }

  @override
  Future<void> rejectRequest({
    required String requestId,
    required String reviewerUid,
    required String rejectionReason,
  }) async {
    rejectCalls++;
    reason = rejectionReason;
    if (failure != null) throw failure!;
    if (completer != null) await completer!.future;
  }

  @override
  Future<List<AccessRequestRecord>> getPendingRequests({
    String? siteId,
  }) async => [];

  @override
  Future<void> submitRequest(AccessRequest request) async {}
}

AccessRequestRecord _request() {
  final request = AccessRequest(
    requestId: 'request_1',
    fullName: 'John Doe',
    email: 'john@example.com',
    company: 'Trinode',
    phone: '+123456789',
    department: 'Operations',
    message: 'Please grant access.',
  );
  return AccessRequestRecord(
    id: 'request_1',
    request: request,
    status: AccessRequestStatus.pending,
  );
}

AppUser _admin() => AppUser(
  id: 'admin_uid',
  name: 'Admin User',
  email: 'admin@example.com',
  role: UserRole.admin,
  siteAccessIds: const ['site_1', 'site_3'],
);

ReviewAccessRequestViewModel _viewModel(_ReviewRepositoryFake repository) {
  return ReviewAccessRequestViewModel(
    request: _request(),
    reviewer: _admin(),
    accessRequestRepository: repository,
    settingsRepository: MockSettingsRepository(
      MockBaitGuardDataSource.seeded(),
    ),
  );
}

void main() {
  test('approval validates role and facility before repository call', () async {
    final repository = _ReviewRepositoryFake();
    final viewModel = _viewModel(repository);
    await viewModel.loadFacilities();

    expect(await viewModel.approve(), isFalse);
    expect(viewModel.roleError, 'Select a valid user role.');
    expect(viewModel.facilityError, 'Select at least one facility.');
    expect(repository.approveCalls, 0);
  });

  test(
    'technician and multiple friendly facilities submit exactly once',
    () async {
      final repository = _ReviewRepositoryFake();
      final viewModel = _viewModel(repository);
      await viewModel.loadFacilities();
      viewModel.selectRole(UserRole.technician);
      viewModel.toggleFacility('site_1');
      viewModel.toggleFacility('site_3');

      expect(await viewModel.approve(), isTrue);

      expect(repository.approveCalls, 1);
      expect(repository.role, UserRole.technician);
      expect(repository.facilityIds, unorderedEquals(['site_1', 'site_3']));
      expect(viewModel.facilities.map((facility) => facility.name), [
        'Warehouse A',
        'Distribution Center',
      ]);
    },
  );

  test('duplicate approve submission is prevented while loading', () async {
    final repository = _ReviewRepositoryFake()..completer = Completer<void>();
    final viewModel = _viewModel(repository);
    await viewModel.loadFacilities();
    viewModel.selectRole(UserRole.viewer);
    viewModel.toggleFacility('site_1');

    final first = viewModel.approve();
    expect(viewModel.isSubmitting, isTrue);
    expect(await viewModel.approve(), isFalse);
    expect(repository.approveCalls, 1);
    repository.completer!.complete();
    expect(await first, isTrue);
  });

  test(
    'network and already-reviewed errors preserve approval selections',
    () async {
      for (final entry in {
        AccessRequestFailureType.unavailable:
            'Unable to complete this action. Check your connection and try again.',
        AccessRequestFailureType.alreadyReviewed:
            'This request has already been reviewed.',
      }.entries) {
        final repository = _ReviewRepositoryFake()
          ..failure = AccessRequestFailure(entry.key);
        final viewModel = _viewModel(repository);
        await viewModel.loadFacilities();
        viewModel.selectRole(UserRole.viewer);
        viewModel.toggleFacility('site_1');

        expect(await viewModel.approve(), isFalse);
        expect(viewModel.errorMessage, entry.value);
        expect(viewModel.selectedRole, UserRole.viewer);
        expect(viewModel.selectedFacilityIds, contains('site_1'));
      }
    },
  );

  test('rejection trims optional reason and enforces 300 characters', () async {
    final repository = _ReviewRepositoryFake();
    final viewModel = _viewModel(repository);
    viewModel.setRejectionReason('  Not eligible  ');

    expect(await viewModel.reject(), isTrue);
    expect(repository.reason, 'Not eligible');

    final invalid = _viewModel(_ReviewRepositoryFake())
      ..setRejectionReason(List.filled(301, 'x').join());
    expect(await invalid.reject(), isFalse);
    expect(invalid.reasonError, contains('300'));
  });

  test(
    'reviewed item removal immediately produces pending empty state',
    () async {
      final recordsRepository = _PendingListRepository([_request()]);
      final list = PendingRequestsViewModel(repository: recordsRepository);
      await list.load();

      list.removeReviewedRequest('request_1');

      expect(list.pendingCount, 0);
      expect(list.status, PendingRequestsStatus.success);
    },
  );

  testWidgets(
    'approval UI shows applicant, allowed roles, and friendly names',
    (tester) async {
      final viewModel = _viewModel(_ReviewRepositoryFake());
      await viewModel.loadFacilities();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: const ApproveRequestScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Technician'), findsOneWidget);
      expect(find.text('Viewer'), findsOneWidget);
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Warehouse A'), findsOneWidget);
      expect(find.text('Distribution Center'), findsOneWidget);
      expect(find.text('site_1'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Approve button pushes the nested route and returns reviewed result',
    (tester) async {
      final repository = _PendingListRepository([_request()]);
      final settingsRepository = MockSettingsRepository(
        MockBaitGuardDataSource.seeded(),
      );
      final navigatorKey = GlobalKey<NavigatorState>();
      var dashboardSignals = 0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AccessRequestRepository>.value(value: repository),
          ],
          child: MaterialApp(
            home: Navigator(
              key: navigatorKey,
              initialRoute: RouteNames.pendingRequests,
              onGenerateRoute: (settings) {
                if (settings.name == RouteNames.approveRequest) {
                  final request = settings.arguments;
                  expect(request, isA<AccessRequestRecord>());
                  return MaterialPageRoute<String>(
                    settings: settings,
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => ReviewAccessRequestViewModel(
                        request: request! as AccessRequestRecord,
                        reviewer: _admin(),
                        accessRequestRepository: repository,
                        settingsRepository: settingsRepository,
                      ),
                      child: const ApproveRequestScreen(),
                    ),
                  );
                }
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) =>
                        PendingRequestsViewModel(repository: repository)
                          ..load(),
                    child: PendingRequestsScreen(
                      onApproveRequest: (request) =>
                          navigatorKey.currentState!.pushNamed<String>(
                            RouteNames.approveRequest,
                            arguments: request,
                          ),
                      onRequestReviewed: (_) async => dashboardSignals++,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final approveButton = find.byKey(const Key('approve_request_1'));
      expect(approveButton, findsOneWidget);
      final button = tester.widget<FilledButton>(approveButton);
      expect(button.onPressed, isNotNull);
      await tester.tap(approveButton);
      await tester.pumpAndSettle();

      expect(find.byType(ApproveRequestScreen), findsOneWidget);
      expect(find.text('Approve Request'), findsOneWidget);
      expect(find.text('JD'), findsOneWidget);
      expect(find.text('Warehouse A'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Technician'));
      final warehouseOption = find.text('Warehouse A');
      await tester.ensureVisible(warehouseOption);
      await tester.tap(warehouseOption);
      final submit = find.text('Approve Access');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repository.approveCalls, 1);
      expect(dashboardSignals, 1);
      expect(find.byType(ApproveRequestScreen), findsNothing);
      expect(find.text('No pending requests'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
    },
  );
}

class _PendingListRepository extends _ReviewRepositoryFake {
  _PendingListRepository(this.records);

  final List<AccessRequestRecord> records;

  @override
  Future<List<AccessRequestRecord>> getPendingRequests({
    String? siteId,
  }) async => records;
}
