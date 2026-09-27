import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/data/repositories/mock/mock_settings_repository.dart';
import 'package:baitguard/domain/models/administrator_contact.dart';
import 'package:baitguard/domain/models/settings_facility_option.dart';
import 'package:baitguard/domain/models/user_settings.dart';
import 'package:baitguard/domain/repositories/settings_repository.dart';
import 'package:baitguard/features/settings/view_models/change_password_view_model.dart';
import 'package:baitguard/features/settings/view_models/contact_admin_view_model.dart';
import 'package:baitguard/domain/models/authenticated_identity.dart';
import 'package:baitguard/domain/repositories/auth_repository.dart';

class _Batch4Repository implements SettingsRepository {
  Completer<void>? passwordCompleter;
  Completer<void>? messageCompleter;
  int passwordCalls = 0;
  int messageCalls = 0;
  String? sentMessage;

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) {
    passwordCalls++;
    return passwordCompleter?.future ?? Future.value();
  }

  @override
  Future<AdministratorContact> getAdministratorContact(String userId) async {
    return const AdministratorContact(
      id: 'admin_1',
      name: 'Alex Rivera',
      roleLabel: 'SYSTEM ADMINISTRATOR',
      email: 'admin@baitguard.com',
      phoneNumber: '+1 555 987 6543',
    );
  }

  @override
  Future<void> sendAdministratorMessage({
    required String userId,
    required String administratorId,
    required String message,
  }) {
    messageCalls++;
    sentMessage = message;
    return messageCompleter?.future ?? Future.value();
  }

  @override
  Future<String?> getFacilityDisplayName(String siteId) async => null;

  @override
  Future<List<SettingsFacilityOption>> getPermittedFacilities(
    List<String> permittedSiteIds,
  ) async => const [];

  @override
  Future<UserSettings> getSettings(String userId) => throw UnimplementedError();

  @override
  Future<void> updateSettings(UserSettings settings) =>
      throw UnimplementedError();
}

class _Batch4AuthRepository extends AuthRepository {
  Completer<void>? passwordCompleter;
  int passwordCalls = 0;

  @override
  Stream<AuthenticatedIdentity?> authStateChanges() => const Stream.empty();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    passwordCalls++;
    return passwordCompleter?.future ?? Future.value();
  }

  @override
  Future<AuthenticatedIdentity?> getCurrentIdentity() async => null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AuthenticatedIdentity> signIn(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

void _setValidPassword(ChangePasswordViewModel viewModel) {
  viewModel.updateCurrentPassword('old-password');
  viewModel.updateNewPassword('Secure1!');
  viewModel.updateConfirmPassword('Secure1!');
}

void main() {
  group('ChangePasswordViewModel', () {
    test('validates required fields and mismatched confirmation', () {
      final viewModel = ChangePasswordViewModel(
        authRepository: _Batch4AuthRepository(),
      );

      expect(viewModel.validate(), 'Current password is required.');
      viewModel.updateCurrentPassword('old-password');
      viewModel.updateNewPassword('Secure1!');
      viewModel.updateConfirmPassword('Different1!');
      expect(viewModel.validate(), 'New passwords do not match.');
    });

    test('toggles all password visibility states', () {
      final viewModel = ChangePasswordViewModel(
        authRepository: _Batch4AuthRepository(),
      );

      viewModel.toggleCurrentPasswordVisibility();
      viewModel.toggleNewPasswordVisibility();
      viewModel.toggleConfirmPasswordVisibility();

      expect(viewModel.showCurrentPassword, isTrue);
      expect(viewModel.showNewPassword, isTrue);
      expect(viewModel.showConfirmPassword, isTrue);
    });

    test('calculates password strength from displayed requirements', () {
      final viewModel = ChangePasswordViewModel(
        authRepository: _Batch4AuthRepository(),
      );

      viewModel.updateNewPassword('abc');
      expect(viewModel.strength, PasswordStrength.weak);
      viewModel.updateNewPassword('LongPassword');
      expect(viewModel.strength, PasswordStrength.medium);
      viewModel.updateNewPassword('Secure1!');
      expect(viewModel.strength, PasswordStrength.strong);
    });

    test(
      'prevents duplicate submit while saving and clears on success',
      () async {
        final repository = _Batch4AuthRepository()
          ..passwordCompleter = Completer<void>();
        final viewModel = ChangePasswordViewModel(authRepository: repository);
        _setValidPassword(viewModel);

        final firstSubmit = viewModel.submit();
        expect(viewModel.isSaving, isTrue);
        expect(await viewModel.submit(), isFalse);
        expect(repository.passwordCalls, 1);

        repository.passwordCompleter!.complete();
        expect(await firstSubmit, isTrue);
        expect(viewModel.currentPassword, isEmpty);
        expect(viewModel.newPassword, isEmpty);
        expect(viewModel.confirmPassword, isEmpty);
      },
    );

    test('mock repository never persists raw password values', () async {
      final dataSource = MockBaitGuardDataSource.seeded();
      final repository = MockSettingsRepository(dataSource);
      final userSnapshot = dataSource.users.toList();
      final settingsSnapshot = dataSource.getUserSettings('viewer_1');

      await repository.changePassword(
        userId: 'viewer_1',
        currentPassword: 'old-password',
        newPassword: 'Secure1!',
      );

      expect(dataSource.users, orderedEquals(userSnapshot));
      expect(dataSource.getUserSettings('viewer_1'), same(settingsSnapshot));
    });
  });

  group('ContactAdminViewModel', () {
    test('loads administrator data from repository', () async {
      final viewModel = ContactAdminViewModel(
        repository: _Batch4Repository(),
        userId: 'viewer_1',
      );

      await viewModel.load();

      expect(viewModel.administrator?.name, 'Alex Rivera');
      expect(viewModel.administrator?.email, 'admin@baitguard.com');
      expect(viewModel.administrator?.phoneNumber, '+1 555 987 6543');
    });

    test(
      'empty message does not send and character count is bounded by validation',
      () async {
        final repository = _Batch4Repository();
        final viewModel = ContactAdminViewModel(
          repository: repository,
          userId: 'viewer_1',
        );
        await viewModel.load();

        expect(await viewModel.send(), isFalse);
        expect(repository.messageCalls, 0);

        viewModel.updateMessage(
          'x' * (ContactAdminViewModel.maxMessageLength + 1),
        );
        expect(viewModel.characterCount, 501);
        expect(viewModel.validate(), contains('500'));
      },
    );

    test('prevents duplicate send and emits success event', () async {
      final repository = _Batch4Repository()
        ..messageCompleter = Completer<void>();
      final viewModel = ContactAdminViewModel(
        repository: repository,
        userId: 'viewer_1',
      );
      await viewModel.load();
      viewModel.updateMessage('Please review station access.');

      final firstSend = viewModel.send();
      expect(viewModel.isSending, isTrue);
      expect(await viewModel.send(), isFalse);
      expect(repository.messageCalls, 1);

      repository.messageCompleter!.complete();
      expect(await firstSend, isTrue);
      expect(viewModel.successEventId, 1);
      expect(viewModel.message, isEmpty);
      expect(repository.sentMessage, 'Please review station access.');
    });
  });
}
