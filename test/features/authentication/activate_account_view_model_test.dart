import 'package:flutter_test/flutter_test.dart';

import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/account_activation_failure.dart';
import 'package:baitguard/domain/models/approved_access_invitation.dart';
import 'package:baitguard/domain/models/auth_failure.dart';
import 'package:baitguard/domain/models/authenticated_identity.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/account_activation_repository.dart';
import 'package:baitguard/domain/repositories/auth_repository.dart';
import 'package:baitguard/features/authentication/view_models/activate_account_view_model.dart';

void main() {
  test(
    'creates account once, sends verification, and clears passwords',
    () async {
      final auth = _AuthFake();
      final viewModel = ActivateAccountViewModel(
        authRepository: auth,
        activationRepository: _ActivationFake(),
        sessionController: AppSessionController(),
      );
      viewModel.setEmail('  USER@Example.com ');
      viewModel.setPassword('Strong1!');
      viewModel.setConfirmation('Strong1!');

      expect(await viewModel.submit(), isTrue);
      expect(auth.createCalls, 1);
      expect(auth.createdEmail, 'user@example.com');
      expect(auth.verificationCalls, 1);
      expect(viewModel.password, isEmpty);
      expect(viewModel.confirmation, isEmpty);
      expect(viewModel.stage, ActivateAccountStage.verification);
    },
  );

  test('verified identity activates approved role and facilities', () async {
    final auth = _AuthFake()..verified = true;
    final session = AppSessionController();
    final activation = _ActivationFake();
    final viewModel = ActivateAccountViewModel(
      authRepository: auth,
      activationRepository: activation,
      sessionController: session,
    );

    expect(await viewModel.checkVerification(), isTrue);
    expect(activation.findCalls, 1);
    expect(activation.activateCalls, 1);
    expect(session.currentUser?.role, UserRole.technician);
    expect(session.currentUser?.siteAccessIds, ['site_1']);
  });

  test('forced token refresh completes before invitation lookup', () async {
    final order = <String>[];
    final auth = _AuthFake()
      ..verified = true
      ..order = order;
    final activation = _ActivationFake(order);
    final viewModel = ActivateAccountViewModel(
      authRepository: auth,
      activationRepository: activation,
      sessionController: AppSessionController(),
    );

    expect(await viewModel.checkVerification(), isTrue);
    expect(order, ['reload', 'token-refresh', 'invitation-lookup']);
  });

  test(
    'unverified identity never refreshes token or queries invitation',
    () async {
      final auth = _AuthFake();
      final activation = _ActivationFake();
      final viewModel = ActivateAccountViewModel(
        authRepository: auth,
        activationRepository: activation,
        sessionController: AppSessionController(),
      );

      expect(await viewModel.checkVerification(), isFalse);
      expect(auth.tokenRefreshCalls, 0);
      expect(activation.findCalls, 0);
      expect(viewModel.errorMessage, 'Your email has not been verified yet.');
    },
  );

  test('token refresh network failure preserves verification state', () async {
    final auth = _AuthFake()
      ..verified = true
      ..tokenRefreshFailure = const AuthFailure(AuthFailureType.network);
    final activation = _ActivationFake();
    final viewModel = ActivateAccountViewModel(
      authRepository: auth,
      activationRepository: activation,
      sessionController: AppSessionController(),
    )..stage = ActivateAccountStage.verification;

    expect(await viewModel.checkVerification(), isFalse);
    expect(viewModel.stage, ActivateAccountStage.verification);
    expect(activation.findCalls, 0);
    expect(
      viewModel.errorMessage,
      'Unable to connect. Check your internet connection and try again.',
    );
  });

  test('permission failure after refresh creates no session', () async {
    final auth = _AuthFake()..verified = true;
    final activation = _ActivationFake()
      ..findFailure = const AccountActivationFailure(
        AccountActivationFailureType.permissionDenied,
      );
    final session = AppSessionController();
    final viewModel = ActivateAccountViewModel(
      authRepository: auth,
      activationRepository: activation,
      sessionController: session,
    );

    expect(await viewModel.checkVerification(), isFalse);
    expect(auth.tokenRefreshCalls, 1);
    expect(session.currentUser, isNull);
    expect(
      viewModel.errorMessage,
      'Account activation could not be authorized.',
    );
  });

  test('validation rejects weak and mismatched passwords', () async {
    final auth = _AuthFake();
    final viewModel = ActivateAccountViewModel(
      authRepository: auth,
      activationRepository: _ActivationFake(),
      sessionController: AppSessionController(),
    );
    viewModel.setEmail('user@example.com');
    viewModel.setPassword('weak');
    viewModel.setConfirmation('different');

    expect(await viewModel.submit(), isFalse);
    expect(auth.createCalls, 0);
    expect(viewModel.passwordError, isNotNull);
    expect(viewModel.confirmationError, isNotNull);
  });
}

class _AuthFake extends AuthRepository {
  bool verified = false;
  int createCalls = 0;
  int verificationCalls = 0;
  String? createdEmail;
  int tokenRefreshCalls = 0;
  AuthFailure? tokenRefreshFailure;
  List<String>? order;

  AuthenticatedIdentity get identity => AuthenticatedIdentity(
    uid: 'uid-1',
    email: 'user@example.com',
    emailVerified: verified,
  );

  @override
  Future<AuthenticatedIdentity> createAccount({
    required String email,
    required String password,
  }) async {
    createCalls++;
    createdEmail = email;
    return identity;
  }

  @override
  Future<AuthenticatedIdentity?> getCurrentIdentity() async => identity;

  @override
  Future<AuthenticatedIdentity?> reloadCurrentIdentity() async {
    order?.add('reload');
    return identity;
  }

  @override
  Future<void> refreshCurrentUserToken() async {
    tokenRefreshCalls++;
    order?.add('token-refresh');
    if (tokenRefreshFailure != null) throw tokenRefreshFailure!;
  }

  @override
  Future<void> sendEmailVerification() async => verificationCalls++;

  @override
  Stream<AuthenticatedIdentity?> authStateChanges() => const Stream.empty();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AuthenticatedIdentity> signIn(String email, String password) async =>
      identity;

  @override
  Future<void> signOut() async {}
}

class _ActivationFake implements AccountActivationRepository {
  _ActivationFake([this.order]);

  final List<String>? order;
  int findCalls = 0;
  int activateCalls = 0;
  AccountActivationFailure? findFailure;

  final invitation = const ApprovedAccessInvitation(
    requestId: 'request-1',
    fullName: 'Test User',
    email: 'user@example.com',
    company: 'Trinode',
    department: '',
    phone: '+923001234567',
    assignedRole: UserRole.technician,
    assignedFacilityIds: ['site_1'],
  );

  @override
  Future<ApprovedAccessInvitation>
  findApprovedInvitationForCurrentUser() async {
    findCalls++;
    order?.add('invitation-lookup');
    if (findFailure != null) throw findFailure!;
    return invitation;
  }

  @override
  Future<AppUser> activateApprovedAccount({
    required ApprovedAccessInvitation invitation,
    required String firebaseUid,
  }) async {
    activateCalls++;
    return AppUser(
      id: firebaseUid,
      name: invitation.fullName,
      email: invitation.email,
      role: invitation.assignedRole,
      siteAccessIds: invitation.assignedFacilityIds,
    );
  }
}
