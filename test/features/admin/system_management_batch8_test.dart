import 'dart:async';

import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/data/repositories/firebase/firestore_user_repository.dart';
import 'package:baitguard/domain/models/administrator_contact.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/settings_facility_option.dart';
import 'package:baitguard/domain/models/user_profile_failure.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/models/user_settings.dart';
import 'package:baitguard/domain/repositories/settings_repository.dart';
import 'package:baitguard/domain/repositories/user_repository.dart';
import 'package:baitguard/features/admin/view_models/system_management_view_model.dart';
import 'package:baitguard/features/admin/views/system_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test(
    'Firestore mapping supports missing displayName and optional fields',
    () {
      final user = FirestoreUserRepository.mapProfile('uid-1', {
        'uid': 'uid-1',
        'email': 'onepart@example.com',
        'role': 'viewer',
        'status': 'active',
        'facilityIds': <String>[],
        'firstName': 'OnePart',
      });
      expect(user.name, 'OnePart');
      expect(user.jobTitle, isNull);
      expect(user.department, isNull);
    },
  );

  test('active admin loads, sorts, and calculates real user counts', () async {
    final users = _UserRepositoryFake([
      _user('3', 'Viewer Person', UserRole.viewer, active: false),
      _user('1', 'Admin Person', UserRole.admin),
      _user('2', 'Tech Person', UserRole.technician),
    ]);
    final viewModel = _viewModel(users: users);

    await viewModel.load();

    expect(viewModel.status, SystemManagementStatus.success);
    expect(viewModel.users.map((user) => user.name), [
      'Admin Person',
      'Tech Person',
      'Viewer Person',
    ]);
    expect(viewModel.totalUsers, 3);
    expect(viewModel.adminCount, 1);
    expect(viewModel.technicianCount, 1);
    expect(viewModel.viewerCount, 1);
    expect(viewModel.activeCount, 2);
    expect(viewModel.disabledCount, 1);
  });

  for (final role in [UserRole.technician, UserRole.viewer]) {
    test('${role.name} is denied without reading users', () async {
      final repository = _UserRepositoryFake(const []);
      final viewModel = _viewModel(users: repository, sessionRole: role);
      await viewModel.load();
      expect(viewModel.status, SystemManagementStatus.denied);
      expect(repository.calls, 0);
    });
  }

  test('inactive admin and missing session are denied', () async {
    final repository = _UserRepositoryFake(const []);
    final inactive = _viewModel(users: repository, active: false);
    await inactive.load();
    expect(inactive.status, SystemManagementStatus.denied);

    final missingSession = SystemManagementViewModel(
      userRepository: repository,
      settingsRepository: _SettingsRepositoryFake(),
      sessionController: AppSessionController(),
    );
    await missingSession.load();
    expect(missingSession.status, SystemManagementStatus.denied);
    expect(repository.calls, 0);
  });

  test('permission and unavailable failures map safely', () async {
    final permission = _UserRepositoryFake(const [])
      ..failure = const UserProfileFailure(
        UserProfileFailureType.permissionDenied,
      );
    final denied = _viewModel(users: permission);
    await denied.load();
    expect(
      denied.errorMessage,
      'You do not have permission to view user management.',
    );

    final unavailable = _UserRepositoryFake(const [])
      ..failure = const UserProfileFailure(UserProfileFailureType.unavailable);
    final failed = _viewModel(users: unavailable);
    await failed.load();
    expect(
      failed.errorMessage,
      'Users could not be loaded. Pull to refresh or try again.',
    );
  });

  test(
    'duplicate load is prevented and refresh preserves previous users',
    () async {
      final repository = _UserRepositoryFake([
        _user('1', 'User', UserRole.viewer),
      ])..completer = Completer<List<AppUser>>();
      final viewModel = _viewModel(users: repository);
      final first = viewModel.load();
      final second = viewModel.load();
      await Future<void>.delayed(Duration.zero);
      expect(repository.calls, 1);
      repository.completer!.complete(repository.users);
      await Future.wait([first, second]);
      expect(viewModel.totalUsers, 1);

      repository.completer = null;
      repository.failure = const UserProfileFailure(
        UserProfileFailureType.unavailable,
      );
      await viewModel.refresh();
      expect(viewModel.totalUsers, 1);
      expect(viewModel.status, SystemManagementStatus.success);
      expect(viewModel.refreshErrorEventId, 1);
      expect(
        viewModel.refreshErrorMessage,
        'Users could not be loaded. Pull to refresh or try again.',
      );
    },
  );

  test('initials support one-part and email fallback names', () {
    expect(
      SystemManagementViewModel.initials(_user('1', 'MJ', UserRole.viewer)),
      'MJ',
    );
    expect(
      SystemManagementViewModel.initials(
        _user('2', '', UserRole.viewer, email: 'fallback@example.com'),
      ),
      'FA',
    );
  });

  testWidgets('screen renders Figma cards, real roles, sites, and actions', (
    tester,
  ) async {
    final viewModel = _viewModel(
      users: _UserRepositoryFake([
        _user('1', 'Alex Rivera', UserRole.admin),
        _user('2', 'Sarah C', UserRole.technician),
        _user('3', 'MJ', UserRole.viewer),
      ]),
    );
    await viewModel.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(home: SystemManagementScreen()),
      ),
    );

    expect(find.text('System Management'), findsOneWidget);
    expect(find.text('User Management'), findsOneWidget);
    expect(find.text('Site Management'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Technician'), findsOneWidget);
    expect(find.text('Viewer'), findsOneWidget);
    expect(find.text('Warehouse A'), findsOneWidget);
    expect(find.text('+ Add User'), findsOneWidget);
    expect(find.text('+ Add Site'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty and denied states remain inside management layout', (
    tester,
  ) async {
    final empty = _viewModel(users: _UserRepositoryFake(const []));
    await empty.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: empty,
        child: const MaterialApp(home: SystemManagementScreen()),
      ),
    );
    expect(find.text('No users found.'), findsOneWidget);
    expect(find.text('Site Management'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

SystemManagementViewModel _viewModel({
  required _UserRepositoryFake users,
  UserRole sessionRole = UserRole.admin,
  bool active = true,
}) {
  final session = AppSessionController()
    ..establishSession(
      _user(
        'admin',
        'Current Admin',
        sessionRole,
        active: active,
        facilities: const ['site_1'],
      ),
    );
  return SystemManagementViewModel(
    userRepository: users,
    settingsRepository: _SettingsRepositoryFake(),
    sessionController: session,
  );
}

AppUser _user(
  String id,
  String name,
  UserRole role, {
  bool active = true,
  String email = 'user@example.com',
  List<String> facilities = const ['site_1'],
}) => AppUser(
  id: id,
  name: name,
  email: email,
  role: role,
  isActive: active,
  siteAccessIds: facilities,
);

class _UserRepositoryFake implements UserRepository {
  _UserRepositoryFake(this.users);

  final List<AppUser> users;
  int calls = 0;
  UserProfileFailure? failure;
  Completer<List<AppUser>>? completer;

  @override
  Future<List<AppUser>> getUsers() async {
    calls++;
    if (failure != null) throw failure!;
    return completer?.future ?? users;
  }

  @override
  Future<AppUser?> getUserById(String id) async => null;

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
  Future<AppUser> updateManagedUserAccess(dynamic request) =>
      throw UnimplementedError();
  @override
  Future<AppUser> updateUser(AppUser user) => throw UnimplementedError();
}

class _SettingsRepositoryFake implements SettingsRepository {
  @override
  Future<List<SettingsFacilityOption>> getPermittedFacilities(
    List<String> permittedSiteIds,
  ) async => const [
    SettingsFacilityOption(
      id: 'site_1',
      name: 'Warehouse A',
      stationCount: 28,
      offlineStationCount: 0,
    ),
  ];

  @override
  Future<String?> getFacilityDisplayName(String siteId) async => 'Warehouse A';

  @override
  Future<UserSettings> getSettings(String userId) => throw UnimplementedError();

  @override
  Future<void> updateSettings(UserSettings settings) =>
      throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) => throw UnimplementedError();

  @override
  Future<AdministratorContact> getAdministratorContact(String userId) =>
      throw UnimplementedError();

  @override
  Future<void> sendAdministratorMessage({
    required String userId,
    required String administratorId,
    required String message,
  }) => throw UnimplementedError();
}
