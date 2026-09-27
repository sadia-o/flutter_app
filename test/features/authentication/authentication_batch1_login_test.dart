import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:baitguard/app/navigation/authenticated_destination_resolver.dart';
import 'package:baitguard/app/navigation/route_names.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/auth_failure.dart';
import 'package:baitguard/domain/models/authenticated_identity.dart';
import 'package:baitguard/domain/models/user_profile_failure.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/auth_repository.dart';
import 'package:baitguard/domain/repositories/user_repository.dart';
import 'package:baitguard/features/authentication/view_models/login_view_model.dart';
import 'package:baitguard/data/repositories/mock/in_memory_login_preferences_repository.dart';

class _FakeAuthRepository extends AuthRepository {
  AuthenticatedIdentity? identity = const AuthenticatedIdentity(
    uid: 'firebase_uid',
    email: 'user@example.com',
    emailVerified: true,
  );
  AuthFailure? signInFailure;
  Completer<AuthenticatedIdentity>? signInCompleter;
  int signInCalls = 0;
  int signOutCalls = 0;
  String? receivedEmail;
  String? receivedPassword;

  @override
  Stream<AuthenticatedIdentity?> authStateChanges() => Stream.value(identity);

  @override
  Future<AuthenticatedIdentity?> getCurrentIdentity() async => identity;

  @override
  Future<AuthenticatedIdentity> signIn(String email, String password) async {
    signInCalls++;
    receivedEmail = email;
    receivedPassword = password;
    if (signInFailure != null) throw signInFailure!;
    if (signInCompleter != null) return signInCompleter!.future;
    return identity!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {
    signOutCalls++;
    identity = null;
  }
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<AppUser> updateManagedUserAccess(dynamic request) =>
      throw UnimplementedError();
  AppUser? profile;
  UserProfileFailure? failure;

  @override
  Future<AppUser?> getUserById(String id) async {
    if (failure != null) throw failure!;
    return profile;
  }

  @override
  Future<List<AppUser>> getUsers() async => profile == null ? [] : [profile!];

  @override
  Future<AppUser> updateUser(AppUser user) async => user;

  @override
  Future<AppUser> updateOwnProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required String department,
    required String phone,
    required String bio,
  }) => throw UnimplementedError();
}

AppUser _profile(
  UserRole role, {
  bool active = true,
  List<String> facilityIds = const ['site_1'],
}) {
  return AppUser(
    id: 'firebase_uid',
    name: 'Firebase User',
    email: 'user@example.com',
    role: role,
    isActive: active,
    siteAccessIds: facilityIds,
  );
}

LoginViewModel _viewModel(
  _FakeAuthRepository auth,
  _FakeUserRepository users,
  AppSessionController session,
) {
  return LoginViewModel(
      auth,
      users,
      session,
      InMemoryLoginPreferencesRepository(),
    )
    ..setEmail('  USER@Example.com ')
    ..setPassword('password123');
}

void main() {
  for (final role in UserRole.values) {
    test(
      'successful ${role.name} login establishes session and route',
      () async {
        final auth = _FakeAuthRepository();
        final users = _FakeUserRepository()..profile = _profile(role);
        final session = AppSessionController();
        final viewModel = _viewModel(auth, users, session);

        expect(await viewModel.login(), isTrue);

        expect(auth.receivedEmail, 'user@example.com');
        expect(session.currentUser, same(users.profile));
        expect(viewModel.password, isEmpty);
        expect(
          AuthenticatedDestinationResolver.resolve(role),
          role == UserRole.admin
              ? RouteNames.adminDashboard
              : RouteNames.userDashboard,
        );
      },
    );
  }

  test('invalid credentials map to a safe message', () async {
    final auth = _FakeAuthRepository()
      ..signInFailure = const AuthFailure(AuthFailureType.invalidCredentials);
    final viewModel = _viewModel(
      auth,
      _FakeUserRepository(),
      AppSessionController(),
    );

    expect(await viewModel.login(), isFalse);
    expect(viewModel.generalError, 'Email or password is incorrect.');
  });

  test('network failure maps to a safe message', () async {
    final auth = _FakeAuthRepository()
      ..signInFailure = const AuthFailure(AuthFailureType.network);
    final viewModel = _viewModel(
      auth,
      _FakeUserRepository(),
      AppSessionController(),
    );

    expect(await viewModel.login(), isFalse);
    expect(
      viewModel.generalError,
      'Unable to connect. Check your internet connection and try again.',
    );
  });

  test('Firebase-disabled account maps without loading a profile', () async {
    final auth = _FakeAuthRepository()
      ..signInFailure = const AuthFailure(AuthFailureType.accountDisabled);
    final users = _FakeUserRepository();
    final viewModel = _viewModel(auth, users, AppSessionController());

    expect(await viewModel.login(), isFalse);
    expect(viewModel.generalError, 'Your account has been disabled.');
  });

  test('missing Firestore profile signs out and creates no session', () async {
    final auth = _FakeAuthRepository();
    final session = AppSessionController();
    final viewModel = _viewModel(auth, _FakeUserRepository(), session);

    expect(await viewModel.login(), isFalse);
    expect(auth.signOutCalls, 1);
    expect(session.currentUser, isNull);
    expect(
      viewModel.generalError,
      'Your account profile could not be found. Contact your administrator.',
    );
  });

  test('disabled Firestore profile signs out and creates no session', () async {
    final auth = _FakeAuthRepository();
    final users = _FakeUserRepository()
      ..profile = _profile(UserRole.viewer, active: false);
    final session = AppSessionController();
    final viewModel = _viewModel(auth, users, session);

    expect(await viewModel.login(), isFalse);
    expect(auth.signOutCalls, 1);
    expect(session.currentUser, isNull);
    expect(viewModel.generalError, 'Your account has been disabled.');
  });

  for (final failureType in [
    UserProfileFailureType.unknownRole,
    UserProfileFailureType.unknownStatus,
    UserProfileFailureType.malformed,
  ]) {
    test('$failureType signs out and reports incomplete profile', () async {
      final auth = _FakeAuthRepository();
      final users = _FakeUserRepository()
        ..failure = UserProfileFailure(failureType);
      final session = AppSessionController();
      final viewModel = _viewModel(auth, users, session);

      expect(await viewModel.login(), isFalse);
      expect(auth.signOutCalls, 1);
      expect(session.currentUser, isNull);
      expect(
        viewModel.generalError,
        'Your account profile is incomplete. Contact your administrator.',
      );
      expect(viewModel.generalError, isNot('Email or password is incorrect.'));
    });
  }

  test(
    'permission-denied profile failure has a distinct safe message',
    () async {
      final auth = _FakeAuthRepository();
      final users = _FakeUserRepository()
        ..failure = const UserProfileFailure(
          UserProfileFailureType.permissionDenied,
        );
      final session = AppSessionController();
      final viewModel = _viewModel(auth, users, session);

      expect(await viewModel.login(), isFalse);
      expect(auth.signOutCalls, 1);
      expect(session.currentUser, isNull);
      expect(
        viewModel.generalError,
        'Your account profile could not be accessed.',
      );
      expect(viewModel.generalError, isNot('Email or password is incorrect.'));
    },
  );

  test('profile UID mismatch is rejected and Firebase is signed out', () async {
    final auth = _FakeAuthRepository();
    final users = _FakeUserRepository()
      ..profile = AppUser(
        id: 'different_uid',
        name: 'Firebase User',
        email: 'user@example.com',
        role: UserRole.admin,
      );
    final session = AppSessionController();
    final viewModel = _viewModel(auth, users, session);

    expect(await viewModel.login(), isFalse);
    expect(auth.signOutCalls, 1);
    expect(session.currentUser, isNull);
    expect(
      viewModel.generalError,
      'Your account profile is incomplete. Contact your administrator.',
    );
  });

  test('duplicate login submission is prevented', () async {
    final auth = _FakeAuthRepository()
      ..signInCompleter = Completer<AuthenticatedIdentity>();
    final users = _FakeUserRepository()..profile = _profile(UserRole.viewer);
    final viewModel = _viewModel(auth, users, AppSessionController());

    final firstLogin = viewModel.login();
    expect(viewModel.isLoading, isTrue);
    expect(await viewModel.login(), isFalse);
    expect(auth.signInCalls, 1);

    auth.signInCompleter!.complete(auth.identity!);
    expect(await firstLogin, isTrue);
  });

  test('password remains form-only and is cleared after success', () async {
    final auth = _FakeAuthRepository();
    final users = _FakeUserRepository()..profile = _profile(UserRole.viewer);
    final session = AppSessionController();
    final viewModel = _viewModel(auth, users, session);

    await viewModel.login();

    expect(viewModel.password, isEmpty);
    expect(session.currentUser!.toString(), isNot(contains('password123')));
    expect(session.currentUser!.siteAccessIds, ['site_1']);
  });
}
