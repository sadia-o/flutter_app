import 'dart:async';

import 'package:baitguard/domain/models/access_request.dart';
import 'package:baitguard/domain/models/access_request_failure.dart';
import 'package:baitguard/domain/models/access_request_record.dart';
import 'package:baitguard/domain/repositories/access_request_repository.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/app/navigation/app_router.dart';
import 'package:baitguard/app/navigation/route_names.dart';
import 'package:baitguard/features/admin/view_models/pending_requests_view_model.dart';
import 'package:baitguard/features/admin/views/pending_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _RepositoryFake implements AccessRequestRepository {
  List<AccessRequestRecord> records = [];
  Object? failure;
  Completer<List<AccessRequestRecord>>? completer;
  int reads = 0;
  int writes = 0;

  @override
  Future<List<AccessRequestRecord>> getPendingRequests({String? siteId}) async {
    reads++;
    if (failure != null) throw failure!;
    if (completer != null) return completer!.future;
    return records;
  }

  @override
  Future<void> submitRequest(AccessRequest request) async {
    writes++;
  }

  @override
  Future<void> approveRequest({
    required String requestId,
    required String reviewerUid,
    required UserRole assignedRole,
    required List<String> assignedFacilityIds,
  }) async {
    writes++;
  }

  @override
  Future<void> rejectRequest({
    required String requestId,
    required String reviewerUid,
    required String rejectionReason,
  }) async {
    writes++;
  }
}

AccessRequestRecord _record({
  String id = 'request_1',
  String name = 'John Doe',
  String company = 'Trinode',
  String department = 'UI/UX Designer',
  String message = 'Please grant access.',
  DateTime? submittedAt,
}) {
  final request = AccessRequest(
    requestId: id,
    fullName: name,
    email: 'john@example.com',
    company: company,
    phone: '+123456789',
    department: department,
    message: message,
    submittedAt: submittedAt,
  );
  return AccessRequestRecord(
    id: id,
    request: request,
    status: AccessRequestStatus.pending,
  );
}

Widget _screen(PendingRequestsViewModel viewModel) {
  return MaterialApp(
    home: ChangeNotifierProvider.value(
      value: viewModel,
      child: const PendingRequestsScreen(),
    ),
  );
}

void main() {
  test(
    'initial load exposes real count, today count, and newest first',
    () async {
      final now = DateTime(2026, 7, 29, 10);
      final repository = _RepositoryFake()
        ..records = [
          _record(id: 'old', submittedAt: DateTime(2026, 7, 28)),
          _record(id: 'today', submittedAt: DateTime(2026, 7, 29, 8)),
        ];
      final viewModel = PendingRequestsViewModel(
        repository: repository,
        now: () => now,
      );

      await viewModel.load();

      expect(viewModel.status, PendingRequestsStatus.success);
      expect(viewModel.pendingCount, 2);
      expect(viewModel.newTodayCount, 1);
      expect(viewModel.requests.first.id, 'today');
    },
  );

  test(
    'duplicate load is prevented and refresh failure preserves data',
    () async {
      final repository = _RepositoryFake()
        ..completer = Completer<List<AccessRequestRecord>>();
      final viewModel = PendingRequestsViewModel(repository: repository);

      final first = viewModel.load();
      await viewModel.load();
      expect(repository.reads, 1);
      repository.completer!.complete([_record()]);
      await first;

      repository
        ..completer = null
        ..failure = const AccessRequestFailure(
          AccessRequestFailureType.unavailable,
        );
      await viewModel.refresh();

      expect(viewModel.requests, hasLength(1));
      expect(viewModel.refreshErrorEventId, 1);
    },
  );

  test('permission, malformed, and index failures map safely', () async {
    final expected = {
      AccessRequestFailureType.permissionDenied:
          'You do not have permission to review access requests.',
      AccessRequestFailureType.invalidData:
          'One or more access requests could not be loaded.',
      AccessRequestFailureType.missingIndex:
          'Pending requests are temporarily unavailable while database setup is completed.',
      AccessRequestFailureType.unavailable:
          'Unable to load pending requests. Check your connection and try again.',
    };
    for (final entry in expected.entries) {
      final repository = _RepositoryFake()
        ..failure = AccessRequestFailure(entry.key);
      final viewModel = PendingRequestsViewModel(repository: repository);
      await viewModel.load();
      expect(viewModel.status, PendingRequestsStatus.failure);
      expect(viewModel.errorMessage, entry.value);
    }
  });

  testWidgets(
    'renders Figma card structure and placeholders without mutation',
    (tester) async {
      final repository = _RepositoryFake()
        ..records = [
          _record(name: 'John Doe', message: '', submittedAt: DateTime.now()),
        ];
      final viewModel = PendingRequestsViewModel(repository: repository);
      await viewModel.load();
      await tester.pumpWidget(_screen(viewModel));

      expect(find.text('Pending Requests'), findsOneWidget);
      expect(
        find.byKey(const Key('pending_requests_count_badge')),
        findsOneWidget,
      );
      expect(find.text('JD'), findsOneWidget);
      expect(find.text('Trinode · UI/UX Designer'), findsOneWidget);
      expect(find.text('No additional message provided.'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      expect(repository.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty and error states support refresh and Retry', (
    tester,
  ) async {
    final repository = _RepositoryFake();
    final viewModel = PendingRequestsViewModel(repository: repository);
    await viewModel.load();
    await tester.pumpWidget(_screen(viewModel));
    expect(find.text('No pending requests'), findsOneWidget);
    expect(
      find.text('New access requests will appear here for review.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsNothing);
    expect(viewModel.refreshErrorEventId, 0);

    repository.failure = const AccessRequestFailure(
      AccessRequestFailureType.unavailable,
    );
    await viewModel.load();
    await tester.pump();
    expect(
      find.textContaining('Unable to load pending requests'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  test(
    'successful empty refresh remains success without an error event',
    () async {
      final repository = _RepositoryFake();
      final viewModel = PendingRequestsViewModel(repository: repository);

      await viewModel.load();
      await viewModel.refresh();

      expect(viewModel.status, PendingRequestsStatus.success);
      expect(viewModel.pendingCount, 0);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.refreshErrorEventId, 0);
    },
  );

  test('failed refresh preserves a previously successful empty result', () async {
    final repository = _RepositoryFake();
    final viewModel = PendingRequestsViewModel(repository: repository);
    await viewModel.load();
    repository.failure = const AccessRequestFailure(
      AccessRequestFailureType.missingIndex,
    );

    await viewModel.refresh();

    expect(viewModel.status, PendingRequestsStatus.success);
    expect(viewModel.pendingCount, 0);
    expect(viewModel.refreshErrorEventId, 1);
    expect(
      viewModel.refreshErrorMessage,
      'Pending requests are temporarily unavailable while database setup is completed.',
    );
  });

  testWidgets('narrow viewport and Back are lifecycle safe', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _RepositoryFake()..records = [_record()];
    final viewModel = PendingRequestsViewModel(repository: repository);
    await viewModel.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: viewModel,
                  child: const PendingRequestsScreen(),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('pending_requests_back')));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final role in [UserRole.technician, UserRole.viewer]) {
    testWidgets('${role.name} direct route is denied without repository read', (
      tester,
    ) async {
      final repository = _RepositoryFake();
      final session = AppSessionController()
        ..establishSession(
          AppUser(
            id: role.name,
            name: 'Restricted User',
            email: '${role.name}@example.com',
            role: role,
          ),
        );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: session),
            Provider<AccessRequestRepository>.value(value: repository),
          ],
          child: MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(RouteNames.pendingRequests),
                child: const Text('Open protected route'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open protected route'));
      await tester.pumpAndSettle();

      expect(
        find.text('You do not have permission to review access requests.'),
        findsOneWidget,
      );
      expect(repository.reads, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
