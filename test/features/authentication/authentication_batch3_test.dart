import 'dart:async';

import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/auth_failure.dart';
import 'package:baitguard/domain/models/authenticated_identity.dart';
import 'package:baitguard/domain/models/remembered_login.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/auth_repository.dart';
import 'package:baitguard/domain/repositories/login_preferences_repository.dart';
import 'package:baitguard/domain/repositories/user_repository.dart';
import 'package:baitguard/features/authentication/view_models/login_view_model.dart';
import 'package:baitguard/features/authentication/views/login_screen.dart';
import 'package:baitguard/features/settings/view_models/change_password_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _PreferencesFake implements LoginPreferencesRepository {
  RememberedLogin value = const RememberedLogin(enabled: false);
  int saveCalls = 0;
  int clearCalls = 0;
  int loadCalls = 0;
  String? savedEmail;

  @override
  Future<void> clearRememberedEmail() async {
    clearCalls++;
    value = const RememberedLogin(enabled: false);
    savedEmail = null;
  }

  @override
  Future<RememberedLogin> load() async {
    loadCalls++;
    return value;
  }

  @override
  Future<void> saveRememberedEmail(String email) async {
    saveCalls++;
    savedEmail = email;
    value = RememberedLogin(enabled: true, email: email);
  }
}

class _AuthFake extends AuthRepository {
  final identity = const AuthenticatedIdentity(
    uid: 'firebase-uid',
    email: 'person@example.com',
    emailVerified: true,
  );
  int changePasswordCalls = 0;
  int signInCalls = 0;
  String? receivedCurrentPassword;
  String? receivedNewPassword;
  AuthFailure? changePasswordFailure;
  Completer<void>? changePasswordCompleter;

  @override
  Stream<AuthenticatedIdentity?> authStateChanges() => Stream.value(identity);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
    receivedCurrentPassword = currentPassword;
    receivedNewPassword = newPassword;
    if (changePasswordFailure != null) throw changePasswordFailure!;
    if (changePasswordCompleter != null) {
      await changePasswordCompleter!.future;
    }
  }

  @override
  Future<AuthenticatedIdentity?> getCurrentIdentity() async => identity;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AuthenticatedIdentity> signIn(String email, String password) async {
    signInCalls++;
    return identity;
  }

  @override
  Future<void> signOut() async {}
}

class _UserFake implements UserRepository {
  @override
  Future<AppUser> updateManagedUserAccess(dynamic request) =>
      throw UnimplementedError();
  _UserFake(this.user);

  final AppUser user;

  @override
  Future<AppUser?> getUserById(String id) async => user;

  @override
  Future<List<AppUser>> getUsers() async => [user];

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

  @override
  Future<AppUser> updateUser(AppUser user) async => user;
}

AppUser _user() => AppUser(
  id: 'firebase-uid',
  name: 'Taha Fayyaz',
  email: 'person@example.com',
  role: UserRole.admin,
  siteAccessIds: const ['site_1'],
);

void _setValidPassword(ChangePasswordViewModel viewModel) {
  viewModel.updateCurrentPassword('Current1!');
  viewModel.updateNewPassword('Stronger2!');
  viewModel.updateConfirmPassword('Stronger2!');
}

void main() {
  group('Remember Me', () {
    test('loads remembered email while keeping password empty', () async {
      final preferences = _PreferencesFake()
        ..value = const RememberedLogin(
          enabled: true,
          email: 'person@example.com',
        );
      final viewModel = LoginViewModel(
        _AuthFake(),
        _UserFake(_user()),
        AppSessionController(),
        preferences,
      );

      await viewModel.initializeRememberedEmail();
      await viewModel.initializeRememberedEmail();

      expect(viewModel.rememberMe, isTrue);
      expect(viewModel.email, 'person@example.com');
      expect(viewModel.password, isEmpty);
      expect(preferences.loadCalls, 1);
    });

    test('successful checked login stores only normalized email', () async {
      final preferences = _PreferencesFake();
      final viewModel = LoginViewModel(
        _AuthFake(),
        _UserFake(_user()),
        AppSessionController(),
        preferences,
      );
      viewModel.setEmail(' PERSON@Example.com ');
      viewModel.setPassword('Secret1!');
      viewModel.toggleRememberMe();

      expect(await viewModel.login(), isTrue);

      expect(preferences.saveCalls, 1);
      expect(preferences.savedEmail, 'person@example.com');
      expect(viewModel.password, isEmpty);
    });

    test('unchecked successful login clears remembered email', () async {
      final preferences = _PreferencesFake()
        ..value = const RememberedLogin(
          enabled: true,
          email: 'old@example.com',
        );
      final viewModel = LoginViewModel(
        _AuthFake(),
        _UserFake(_user()),
        AppSessionController(),
        preferences,
      );
      viewModel.setEmail('person@example.com');
      viewModel.setPassword('Secret1!');

      expect(await viewModel.login(), isTrue);

      expect(preferences.clearCalls, 1);
      expect(preferences.savedEmail, isNull);
    });

    testWidgets('Login exposes Android autofill hints without a password', (
      tester,
    ) async {
      final viewModel = LoginViewModel(
        _AuthFake(),
        _UserFake(_user()),
        AppSessionController(),
        _PreferencesFake(),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LoginViewModel>.value(value: viewModel),
            ChangeNotifierProvider(create: (_) => AppSessionController()),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      final configuredHints = fields
          .expand((field) => field.autofillHints ?? const <String>[])
          .toSet();
      expect(configuredHints, contains(AutofillHints.username));
      expect(configuredHints, contains(AutofillHints.email));
      expect(configuredHints, contains(AutofillHints.password));
      final passwordField = fields.firstWhere(
        (field) =>
            field.autofillHints?.contains(AutofillHints.password) ?? false,
      );
      expect(passwordField.controller?.text ?? '', isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('Change Password', () {
    test('submits once and clears all password values', () async {
      final repository = _AuthFake()
        ..changePasswordCompleter = Completer<void>();
      final viewModel = ChangePasswordViewModel(authRepository: repository);
      _setValidPassword(viewModel);

      final first = viewModel.submit();
      expect(await viewModel.submit(), isFalse);
      expect(repository.changePasswordCalls, 1);
      repository.changePasswordCompleter!.complete();

      expect(await first, isTrue);
      expect(repository.receivedCurrentPassword, 'Current1!');
      expect(repository.receivedNewPassword, 'Stronger2!');
      expect(viewModel.currentPassword, isEmpty);
      expect(viewModel.newPassword, isEmpty);
      expect(viewModel.confirmPassword, isEmpty);
    });

    final failureMessages = {
      AuthFailureType.invalidCredentials: 'The current password is incorrect.',
      AuthFailureType.weakPassword: 'Choose a stronger password.',
      AuthFailureType.network:
          'Unable to connect. Check your internet connection and try again.',
      AuthFailureType.noAuthenticatedUser:
          'Your session has expired. Please sign in again.',
    };

    for (final entry in failureMessages.entries) {
      test('maps ${entry.key.name} without exposing Firebase errors', () async {
        final repository = _AuthFake()
          ..changePasswordFailure = AuthFailure(entry.key);
        final viewModel = ChangePasswordViewModel(authRepository: repository);
        _setValidPassword(viewModel);

        expect(await viewModel.submit(), isFalse);
        expect(viewModel.errorMessage, entry.value);
        expect(viewModel.currentPassword, 'Current1!');
        expect(viewModel.errorMessage, isNot(contains('Firebase')));
      });
    }
  });
}
