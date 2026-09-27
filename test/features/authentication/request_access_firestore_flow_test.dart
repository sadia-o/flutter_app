import 'dart:async';

import 'package:baitguard/domain/models/access_request.dart';
import 'package:baitguard/domain/models/access_request_failure.dart';
import 'package:baitguard/domain/models/access_request_record.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/access_request_repository.dart';
import 'package:baitguard/features/authentication/view_models/request_access_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _AccessRequestRepositoryFake implements AccessRequestRepository {
  int submitCalls = 0;
  AccessRequest? submittedRequest;
  AccessRequestFailure? failure;
  Completer<void>? completer;

  @override
  Future<List<AccessRequestRecord>> getPendingRequests({
    String? siteId,
  }) async => const [];

  @override
  Future<void> submitRequest(AccessRequest request) async {
    submitCalls++;
    submittedRequest = request;
    if (failure != null) throw failure!;
    if (completer != null) await completer!.future;
  }

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

void _fillValid(
  RequestAccessViewModel viewModel, {
  String email = ' Person@Example.COM ',
}) {
  viewModel.setFullName('  John Smith  ');
  viewModel.setEmail(email);
  viewModel.setCompany('  Acme Corporation  ');
  viewModel.setPhone('  +1 555 000 0000  ');
}

void main() {
  test('required fields and invalid email are validated locally', () async {
    final repository = _AccessRequestRepositoryFake();
    final viewModel = RequestAccessViewModel(repository);

    expect(await viewModel.submit(), isFalse);
    expect(viewModel.fullNameError, 'Full name is required.');
    expect(viewModel.emailError, 'Company email is required.');
    expect(viewModel.companyError, 'Company or organisation is required.');
    expect(viewModel.phoneError, 'Phone number is required.');

    _fillValid(viewModel, email: 'invalid-email');
    expect(await viewModel.submit(), isFalse);
    expect(viewModel.emailError, 'Enter a valid company email.');
    expect(repository.submitCalls, 0);
  });

  test(
    'trims fields, normalizes email, and stores omitted optionals empty',
    () async {
      final repository = _AccessRequestRepositoryFake();
      final viewModel = RequestAccessViewModel(repository);
      _fillValid(viewModel);

      expect(await viewModel.submit(), isTrue);

      final request = repository.submittedRequest!;
      expect(repository.submitCalls, 1);
      expect(request.fullName, 'John Smith');
      expect(request.email, 'person@example.com');
      expect(request.normalizedEmail, 'person@example.com');
      expect(request.company, 'Acme Corporation');
      expect(request.phone, '+1 555 000 0000');
      expect(request.department, isEmpty);
      expect(request.message, isEmpty);
      expect(request.status, AccessRequestStatus.pending);
    },
  );

  test('optional department and message are trimmed', () async {
    final repository = _AccessRequestRepositoryFake();
    final viewModel = RequestAccessViewModel(repository);
    _fillValid(viewModel);
    viewModel.setDepartment('  Facilities  ');
    viewModel.setMessage('  Please review my request.  ');

    await viewModel.submit();

    expect(repository.submittedRequest!.department, 'Facilities');
    expect(repository.submittedRequest!.message, 'Please review my request.');
  });

  test(
    'duplicate submit is prevented while the first write is pending',
    () async {
      final repository = _AccessRequestRepositoryFake()
        ..completer = Completer<void>();
      final viewModel = RequestAccessViewModel(repository);
      _fillValid(viewModel);

      final first = viewModel.submit();
      expect(viewModel.isLoading, isTrue);
      expect(await viewModel.submit(), isFalse);
      expect(repository.submitCalls, 1);

      repository.completer!.complete();
      expect(await first, isTrue);
      expect(viewModel.isSubmitted, isTrue);
    },
  );

  test('network and permission failures map safely and preserve values', () async {
    for (final entry in {
      AccessRequestFailureType.unavailable:
          'Unable to submit your request. Check your internet connection and try again.',
      AccessRequestFailureType.permissionDenied:
          'Access requests are temporarily unavailable. Please try again later.',
    }.entries) {
      final repository = _AccessRequestRepositoryFake()
        ..failure = AccessRequestFailure(entry.key);
      final viewModel = RequestAccessViewModel(repository);
      _fillValid(viewModel);
      viewModel.setDepartment('Operations');
      viewModel.setMessage('Keep this text');

      expect(await viewModel.submit(), isFalse);
      expect(viewModel.generalError, entry.value);
      expect(viewModel.department, 'Operations');
      expect(viewModel.message, 'Keep this text');
    }
  });

  test('editing clears stale field and repository errors', () async {
    final repository = _AccessRequestRepositoryFake()
      ..failure = const AccessRequestFailure(
        AccessRequestFailureType.unavailable,
      );
    final viewModel = RequestAccessViewModel(repository);
    _fillValid(viewModel);
    await viewModel.submit();
    expect(viewModel.generalError, isNotNull);

    viewModel.setEmail('new@example.com');

    expect(viewModel.generalError, isNull);
    expect(viewModel.emailError, isNull);
  });

  test(
    'payload has no role, facility, password, token, or image fields',
    () async {
      final repository = _AccessRequestRepositoryFake();
      final viewModel = RequestAccessViewModel(repository);
      _fillValid(viewModel);

      await viewModel.submit();

      final request = repository.submittedRequest!;
      expect(request, isA<AccessRequest>());
      expect(
        request.toString(),
        isNot(
          anyOf(contains('password'), contains('token'), contains('image')),
        ),
      );
    },
  );
}
