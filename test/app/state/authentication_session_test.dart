import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/app/state/auth_session_coordinator.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/auth_failure.dart';
import 'package:baitguard/domain/models/authenticated_identity.dart';
import 'package:baitguard/domain/models/user_profile_failure.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/auth_repository.dart';
import 'package:baitguard/domain/repositories/user_repository.dart';

class _SessionAuthRepository extends AuthRepository {
  AuthenticatedIdentity? currentIdentity;
  int signOutCalls = 0;
  bool failSignOut = false;
  Completer<void>? signOutCompleter;

  @override
  Stream<AuthenticatedIdentity?> authStateChanges() =>
      Stream.value(currentIdentity);

  @override
  Future<AuthenticatedIdentity?> getCurrentIdentity() async => currentIdentity;

  @override
  Future<AuthenticatedIdentity> signIn(String email, String password) =>
      throw UnimplementedError();

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
    if (signOutCompleter != null) await signOutCompleter!.future;
    if (failSignOut) {
      throw const AuthFailure(AuthFailureType.network);
    }
    currentIdentity = null;
  }
}

class _SessionUserRepository implements UserRepository {
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
  Future<List<AppUser>> getUsers() async => [];

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

AppUser _sessionProfile(UserRole role, {bool active = true}) {
  return AppUser(
    id: 'uid_1',
    name: 'Restored User',
    email: 'restored@example.com',
    role: role,
    isActive: active,
    siteAccessIds: const ['site_1'],
  );
}

AuthSessionCoordinator _coordinator(
  _SessionAuthRepository auth,
  _SessionUserRepository users,
  AppSessionController session,
) {
  return AuthSessionCoordinator(
    authRepository: auth,
    userRepository: users,
    sessionController: session,
  );
}

void main() {
  test(
    'AppSessionController starts and clears without duplicate notifications',
    () {
      final controller = AppSessionController();
      final user = _sessionProfile(UserRole.viewer);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.establishSession(user);
      controller.establishSession(user);
      controller.clearSession();
      controller.clearSession();

      expect(notifications, 2);
      expect(controller.currentUser, isNull);
    },
  );

  for (final role in UserRole.values) {
    test(
      'restores ${role.name} session from Firebase identity and profile',
      () async {
        final auth = _SessionAuthRepository()
          ..currentIdentity = const AuthenticatedIdentity(
            uid: 'uid_1',
            email: 'restored@example.com',
            emailVerified: true,
          );
        final users = _SessionUserRepository()..profile = _sessionProfile(role);
        final session = AppSessionController();
        final coordinator = _coordinator(auth, users, session);

        await coordinator.initialize();

        expect(coordinator.status, SessionRestorationStatus.authenticated);
        expect(session.currentUser?.role, role);
        expect(session.currentUser?.siteAccessIds, ['site_1']);
        expect(auth.signOutCalls, 0);
      },
    );
  }

  test('restoration with no Firebase identity stays unauthenticated', () async {
    final auth = _SessionAuthRepository();
    final session = AppSessionController();
    final coordinator = _coordinator(auth, _SessionUserRepository(), session);

    await coordinator.initialize();

    expect(coordinator.status, SessionRestorationStatus.unauthenticated);
    expect(session.currentUser, isNull);
  });

  test('missing restoration profile signs out safely', () async {
    final auth = _SessionAuthRepository()
      ..currentIdentity = const AuthenticatedIdentity(
        uid: 'uid_1',
        email: 'restored@example.com',
        emailVerified: true,
      );
    final session = AppSessionController();
    final coordinator = _coordinator(auth, _SessionUserRepository(), session);

    await coordinator.initialize();

    expect(auth.signOutCalls, 1);
    expect(session.currentUser, isNull);
    expect(coordinator.status, SessionRestorationStatus.unauthenticated);
  });

  test('disabled restoration profile signs out safely', () async {
    final auth = _SessionAuthRepository()
      ..currentIdentity = const AuthenticatedIdentity(
        uid: 'uid_1',
        email: 'restored@example.com',
        emailVerified: true,
      );
    final users = _SessionUserRepository()
      ..profile = _sessionProfile(UserRole.viewer, active: false);
    final session = AppSessionController();
    final coordinator = _coordinator(auth, users, session);

    await coordinator.initialize();

    expect(auth.signOutCalls, 1);
    expect(session.currentUser, isNull);
  });

  test('successful central logout signs out before clearing session', () async {
    final auth = _SessionAuthRepository();
    final users = _SessionUserRepository();
    final session = AppSessionController()
      ..establishSession(_sessionProfile(UserRole.admin));
    final coordinator = _coordinator(auth, users, session);

    expect(await coordinator.logout(), isTrue);

    expect(auth.signOutCalls, 1);
    expect(session.currentUser, isNull);
    expect(coordinator.isLoggingOut, isFalse);
  });

  test('duplicate logout is prevented', () async {
    final auth = _SessionAuthRepository()..signOutCompleter = Completer<void>();
    final session = AppSessionController()
      ..establishSession(_sessionProfile(UserRole.viewer));
    final coordinator = _coordinator(auth, _SessionUserRepository(), session);

    final firstLogout = coordinator.logout();
    expect(coordinator.isLoggingOut, isTrue);
    expect(await coordinator.logout(), isFalse);
    expect(auth.signOutCalls, 1);

    auth.signOutCompleter!.complete();
    expect(await firstLogout, isTrue);
  });

  test('logout failure preserves session and always clears loading', () async {
    final auth = _SessionAuthRepository()..failSignOut = true;
    final user = _sessionProfile(UserRole.technician);
    final session = AppSessionController()..establishSession(user);
    final coordinator = _coordinator(auth, _SessionUserRepository(), session);

    expect(await coordinator.logout(), isFalse);

    expect(session.currentUser, same(user));
    expect(coordinator.isLoggingOut, isFalse);
    expect(coordinator.logoutErrorMessage, isNotNull);
  });
}
