import 'dart:async';

import 'package:baitguard/domain/models/auth_failure.dart';
import 'package:baitguard/domain/models/authenticated_identity.dart';
import 'package:baitguard/domain/repositories/auth_repository.dart';
import 'package:baitguard/features/authentication/view_models/forgot_password_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends AuthRepository {
  int resetCalls = 0;
  String? receivedEmail;
  AuthFailure? resetFailure;
  Completer<void>? resetCompleter;

  @override
  Stream<AuthenticatedIdentity?> authStateChanges() => const Stream.empty();

  @override
  Future<AuthenticatedIdentity?> getCurrentIdentity() async => null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCalls++;
    receivedEmail = email;
    if (resetFailure != null) throw resetFailure!;
    if (resetCompleter != null) await resetCompleter!.future;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<AuthenticatedIdentity> signIn(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

void main() {
  late _FakeAuthRepository repository;
  late ForgotPasswordViewModel viewModel;

  setUp(() {
    repository = _FakeAuthRepository();
    viewModel = ForgotPasswordViewModel(repository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('empty and invalid email are rejected locally', () async {
    expect(await viewModel.submit(), isFalse);
    expect(viewModel.emailError, 'Email address is required.');
    expect(repository.resetCalls, 0);

    viewModel.setEmail('not-an-email');
    expect(await viewModel.submit(), isFalse);
    expect(viewModel.emailError, 'Enter a valid email address.');
    expect(repository.resetCalls, 0);
  });

  test('email is trimmed, normalized, and submitted once', () async {
    viewModel.setEmail('  PERSON@Example.COM ');

    expect(await viewModel.submit(), isTrue);

    expect(repository.resetCalls, 1);
    expect(repository.receivedEmail, 'person@example.com');
    expect(viewModel.email, 'person@example.com');
    expect(viewModel.isSuccess, isTrue);
  });

  test('duplicate submission is prevented while loading', () async {
    repository.resetCompleter = Completer<void>();
    viewModel.setEmail('person@example.com');

    final first = viewModel.submit();
    final second = viewModel.submit();

    expect(viewModel.isLoading, isTrue);
    expect(await second, isFalse);
    expect(repository.resetCalls, 1);

    repository.resetCompleter!.complete();
    expect(await first, isTrue);
    expect(viewModel.isLoading, isFalse);
  });

  test('network failure is safe and preserves entered email', () async {
    repository.resetFailure = const AuthFailure(AuthFailureType.network);
    viewModel.setEmail('person@example.com');

    expect(await viewModel.submit(), isFalse);

    expect(
      viewModel.errorMessage,
      'Unable to connect. Check your internet connection and try again.',
    );
    expect(viewModel.email, 'person@example.com');
  });

  test('too many requests receives specific safe feedback', () async {
    repository.resetFailure = const AuthFailure(
      AuthFailureType.tooManyRequests,
    );
    viewModel.setEmail('person@example.com');

    await viewModel.submit();

    expect(
      viewModel.errorMessage,
      'Too many reset attempts. Please wait and try again.',
    );
  });

  test('editing clears stale validation and repository errors', () async {
    repository.resetFailure = const AuthFailure(AuthFailureType.network);
    viewModel.setEmail('person@example.com');
    await viewModel.submit();
    expect(viewModel.errorMessage, isNotNull);

    viewModel.setEmail('other@example.com');

    expect(viewModel.errorMessage, isNull);
    expect(viewModel.emailError, isNull);
  });

  test('resend uses the same normalized repository flow', () async {
    viewModel.setEmail('PERSON@example.com');
    await viewModel.submit();
    await viewModel.resend();

    expect(repository.resetCalls, 2);
    expect(repository.receivedEmail, 'person@example.com');
  });
}
