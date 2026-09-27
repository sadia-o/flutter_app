import 'dart:async';

import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/user_profile_failure.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/user_repository.dart';
import 'package:baitguard/features/settings/view_models/edit_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProfileRepositoryFake implements UserRepository {
  @override
  Future<AppUser> updateManagedUserAccess(dynamic request) =>
      throw UnimplementedError();
  _ProfileRepositoryFake(this.original);

  final AppUser original;
  int calls = 0;
  Completer<AppUser>? completer;
  UserProfileFailure? failure;
  Map<String, String>? submitted;

  @override
  Future<AppUser?> getUserById(String id) async => original;

  @override
  Future<List<AppUser>> getUsers() async => [original];

  @override
  Future<AppUser> updateOwnProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required String department,
    required String phone,
    required String bio,
  }) async {
    calls++;
    submitted = {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'jobTitle': jobTitle,
      'department': department,
      'phone': phone,
      'bio': bio,
    };
    if (failure != null) throw failure!;
    if (completer != null) return completer!.future;
    return AppUser(
      id: original.id,
      name: '$firstName $lastName'.trim(),
      email: original.email,
      role: original.role,
      isActive: original.isActive,
      siteAccessIds: original.siteAccessIds,
      firstName: firstName,
      lastName: lastName,
      jobTitle: jobTitle,
      department: department,
      phoneNumber: phone,
      shortBio: bio,
      company: original.company,
      createdAt: original.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<AppUser> updateUser(AppUser user) async => user;
}

AppUser _legacyUser() => AppUser(
  id: 'firebase-uid',
  name: 'Taha Fayyaz Khan',
  email: 'protected@example.com',
  role: UserRole.admin,
  isActive: true,
  siteAccessIds: const ['site_1', 'site_2'],
  company: 'Protected Company',
  createdAt: DateTime(2025),
);

AppUser _roleUser(UserRole role) => AppUser(
  id: 'firebase-${role.name}',
  name: 'SingleName',
  email: '${role.name}@example.com',
  role: role,
  siteAccessIds: const ['site_1'],
);

void main() {
  test('legacy displayName splits safely into first and remaining names', () {
    final user = _legacyUser();
    final session = AppSessionController()..establishSession(user);

    final viewModel = EditProfileViewModel(
      userRepository: _ProfileRepositoryFake(user),
      sessionController: session,
    );

    expect(viewModel.firstName, 'Taha');
    expect(viewModel.lastName, 'Fayyaz Khan');
  });

  test(
    'save submits editable fields once and preserves protected fields',
    () async {
      final original = _legacyUser();
      final session = AppSessionController()..establishSession(original);
      final repository = _ProfileRepositoryFake(original);
      final viewModel =
          EditProfileViewModel(
              userRepository: repository,
              sessionController: session,
            )
            ..firstName = '  New '
            ..lastName = ' Name  '
            ..jobTitle = ' Inspector '
            ..department = ' Operations '
            ..phoneNumber = ' +92 300 1234567 '
            ..shortBio = ' Updated bio ';
      var sessionNotifications = 0;
      session.addListener(() => sessionNotifications++);

      expect(await viewModel.save(), isTrue);

      expect(repository.calls, 1);
      expect(repository.submitted, {
        'uid': 'firebase-uid',
        'firstName': 'New',
        'lastName': 'Name',
        'jobTitle': 'Inspector',
        'department': 'Operations',
        'phone': '+92 300 1234567',
        'bio': 'Updated bio',
      });
      expect(sessionNotifications, 1);
      expect(session.currentUser!.name, 'New Name');
      expect(session.currentUser!.email, original.email);
      expect(session.currentUser!.role, original.role);
      expect(session.currentUser!.siteAccessIds, original.siteAccessIds);
      expect(session.currentUser!.company, original.company);
      expect(session.currentUser!.createdAt, original.createdAt);
    },
  );

  test(
    'duplicate save is prevented while repository operation is pending',
    () async {
      final original = _legacyUser();
      final repository = _ProfileRepositoryFake(original)
        ..completer = Completer<AppUser>();
      final viewModel = EditProfileViewModel(
        userRepository: repository,
        sessionController: AppSessionController()..establishSession(original),
      );

      final first = viewModel.save();
      expect(await viewModel.save(), isFalse);
      expect(repository.calls, 1);
      repository.completer!.complete(original);
      expect(await first, isTrue);
    },
  );

  test(
    'recoverable failure preserves fields and maps a safe message',
    () async {
      final original = _legacyUser();
      final repository = _ProfileRepositoryFake(
        original,
      )..failure = const UserProfileFailure(UserProfileFailureType.unavailable);
      final viewModel = EditProfileViewModel(
        userRepository: repository,
        sessionController: AppSessionController()..establishSession(original),
      )..firstName = 'Entered';

      expect(await viewModel.save(), isFalse);

      expect(viewModel.firstName, 'Entered');
      expect(
        viewModel.errorMessage,
        'Unable to connect. Check your internet connection and try again.',
      );
    },
  );

  test('first name is required while last name remains optional', () {
    final original = _legacyUser();
    final viewModel = EditProfileViewModel(
      userRepository: _ProfileRepositoryFake(original),
      sessionController: AppSessionController()..establishSession(original),
    );

    viewModel.firstName = '';
    expect(viewModel.validate(), 'First name is required.');
    viewModel.firstName = 'Taha';
    viewModel.lastName = '';
    expect(viewModel.validate(), isNull);
    viewModel.shortBio = 'x' * 201;
    expect(viewModel.validate(), contains('200'));
  });

  test('all optional fields save as trimmed empty strings', () async {
    final original = _legacyUser();
    final repository = _ProfileRepositoryFake(original);
    final session = AppSessionController()..establishSession(original);
    final viewModel =
        EditProfileViewModel(
            userRepository: repository,
            sessionController: session,
          )
          ..firstName = 'OneName'
          ..lastName = '   '
          ..jobTitle = ''
          ..department = ' '
          ..phoneNumber = ''
          ..shortBio = '  ';

    expect(await viewModel.save(), isTrue);
    expect(repository.submitted?['lastName'], '');
    expect(repository.submitted?['jobTitle'], '');
    expect(repository.submitted?['department'], '');
    expect(repository.submitted?['phone'], '');
    expect(repository.submitted?['bio'], '');
    expect(session.currentUser?.name, 'OneName');
  });

  test(
    'genuine permission failure retains a safe authorization message',
    () async {
      final original = _legacyUser();
      final repository = _ProfileRepositoryFake(original)
        ..failure = const UserProfileFailure(
          UserProfileFailureType.permissionDenied,
        );
      final viewModel = EditProfileViewModel(
        userRepository: repository,
        sessionController: AppSessionController()..establishSession(original),
      );

      expect(await viewModel.save(), isFalse);
      expect(
        viewModel.errorMessage,
        'Your profile changes could not be authorized. Please sign in again or contact your administrator.',
      );
    },
  );

  for (final role in UserRole.values) {
    test('${role.name} saves all optional fields empty', () async {
      final original = _roleUser(role);
      final repository = _ProfileRepositoryFake(original);
      final session = AppSessionController()..establishSession(original);
      final viewModel =
          EditProfileViewModel(
              userRepository: repository,
              sessionController: session,
            )
            ..lastName = ''
            ..jobTitle = ''
            ..department = ''
            ..phoneNumber = ''
            ..shortBio = '';

      expect(await viewModel.save(), isTrue);
      expect(session.currentUser?.role, role);
      expect(session.currentUser?.siteAccessIds, original.siteAccessIds);
      expect(repository.submitted?.values, isNot(contains(null)));
    });
  }
}
