import 'dart:async';

import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/administrator_contact.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/settings_facility_option.dart';
import 'package:baitguard/domain/models/user_profile_failure.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/models/user_settings.dart';
import 'package:baitguard/domain/repositories/settings_repository.dart';
import 'package:baitguard/domain/repositories/user_repository.dart';
import 'package:baitguard/features/admin/view_models/user_details_view_model.dart';
import 'package:baitguard/features/admin/view_models/user_management_view_model.dart';
import 'package:baitguard/features/admin/views/user_details_screen.dart';
import 'package:baitguard/features/admin/views/user_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('UserManagementViewModel', () {
    test('active admin loads, sorts, and calculates counts', () async {
      final repository = _UsersFake([
        _user('v', 'Viewer', UserRole.viewer, active: false),
        _user('t', 'Technician', UserRole.technician),
        _user('a', 'Admin', UserRole.admin),
      ]);
      final viewModel = _listViewModel(repository);

      await viewModel.load();

      expect(viewModel.status, UserManagementStatus.success);
      expect(viewModel.users.map((user) => user.id), ['a', 't', 'v']);
      expect(viewModel.totalCount, 3);
      expect(viewModel.activeCount, 2);
      expect(viewModel.disabledCount, 1);
      expect(viewModel.adminCount, 1);
      expect(viewModel.technicianCount, 1);
      expect(viewModel.viewerCount, 1);
    });

    for (final role in [UserRole.technician, UserRole.viewer]) {
      test('${role.name} is denied before repository read', () async {
        final repository = _UsersFake(const []);
        final viewModel = _listViewModel(repository, role: role);
        await viewModel.load();
        expect(viewModel.status, UserManagementStatus.denied);
        expect(repository.getUsersCalls, 0);
      });
    }

    test('disabled admin and missing session are denied', () async {
      final repository = _UsersFake(const []);
      await _listViewModel(repository, active: false).load();
      final missing = UserManagementViewModel(
        userRepository: repository,
        sessionController: AppSessionController(),
      );
      await missing.load();
      expect(repository.getUsersCalls, 0);
      expect(missing.status, UserManagementStatus.denied);
    });

    test('searches all identity fields case-insensitively', () async {
      final viewModel = _listViewModel(
        _UsersFake([
          _user(
            '1',
            'Alexander Rivera',
            UserRole.viewer,
            firstName: 'Alex',
            lastName: 'Rivera',
            email: 'person@example.com',
          ),
          _user('2', 'Taylor', UserRole.technician),
        ]),
      );
      await viewModel.load();
      for (final query in ['ALEXANDER', 'alex', 'rivera', 'PERSON@']) {
        viewModel.updateQuery(query);
        expect(viewModel.filteredUsers.single.id, '1');
      }
      viewModel.updateQuery('');
      expect(viewModel.filteredUsers, hasLength(2));
    });

    test('combines role and status filters and resets', () async {
      final viewModel = _listViewModel(
        _UsersFake([
          _user('1', 'Active Viewer', UserRole.viewer),
          _user('2', 'Disabled Viewer', UserRole.viewer, active: false),
          _user('3', 'Active Tech', UserRole.technician),
        ]),
      );
      await viewModel.load();
      viewModel.selectRole(UserRoleFilter.viewer);
      viewModel.selectStatus(UserStatusFilter.disabled);
      expect(viewModel.filteredUsers.single.id, '2');
      viewModel.updateQuery('missing');
      expect(viewModel.filteredUsers, isEmpty);
      viewModel.resetFilters();
      expect(viewModel.filteredUsers, hasLength(3));
      expect(viewModel.hasFilters, isFalse);
    });

    test('permission and network errors map safely', () async {
      final permission = _UsersFake(const [])
        ..failure = const UserProfileFailure(
          UserProfileFailureType.permissionDenied,
        );
      final denied = _listViewModel(permission);
      await denied.load();
      expect(denied.errorMessage, 'You do not have permission to view users.');

      final network = _UsersFake(
        const [],
      )..failure = const UserProfileFailure(UserProfileFailureType.unavailable);
      final failed = _listViewModel(network);
      await failed.load();
      expect(
        failed.errorMessage,
        'Users could not be loaded. Check your connection and try again.',
      );
    });

    test(
      'duplicate load prevented and failed refresh preserves data/filters',
      () async {
        final repository = _UsersFake([_user('1', 'One', UserRole.viewer)])
          ..completer = Completer<List<AppUser>>();
        final viewModel = _listViewModel(repository);
        final first = viewModel.load();
        final duplicate = viewModel.load();
        await Future<void>.delayed(Duration.zero);
        expect(repository.getUsersCalls, 1);
        repository.completer!.complete(repository.users);
        await Future.wait([first, duplicate]);

        viewModel.selectRole(UserRoleFilter.viewer);
        repository.completer = null;
        repository.failure = const UserProfileFailure(
          UserProfileFailureType.unavailable,
        );
        await viewModel.refresh();
        expect(viewModel.users, hasLength(1));
        expect(viewModel.roleFilter, UserRoleFilter.viewer);
        expect(viewModel.refreshErrorEventId, 1);
      },
    );

    test('name and initials fall back safely', () {
      final user = _user(
        '1',
        '',
        UserRole.viewer,
        email: 'fallback@example.com',
      );
      expect(UserManagementViewModel.displayName(user), 'fallback');
      expect(UserManagementViewModel.initials(user), 'FA');
      expect(
        UserManagementViewModel.initials(
          _user('2', 'محمد خان', UserRole.viewer),
        ),
        isNotEmpty,
      );
    });
  });

  group('UserDetailsViewModel', () {
    test('loads by UID and resolves friendly and unknown facilities', () async {
      final repository = _UsersFake([
        _user(
          'target',
          'Target User',
          UserRole.viewer,
          facilities: const ['site_1', 'unknown'],
        ),
      ]);
      final viewModel = _detailsViewModel(repository);
      await viewModel.load();
      expect(repository.requestedIds, ['target']);
      expect(viewModel.status, UserDetailsStatus.success);
      expect(viewModel.facilities.map((facility) => facility.name), [
        'Warehouse A',
        'Unknown facility',
      ]);
    });

    test('unauthorized session never reads user', () async {
      final repository = _UsersFake(const []);
      final viewModel = _detailsViewModel(repository, role: UserRole.viewer);
      await viewModel.load();
      expect(viewModel.status, UserDetailsStatus.denied);
      expect(repository.requestedIds, isEmpty);
    });

    test('missing, permission, and retry behavior are safe', () async {
      final missing = _detailsViewModel(_UsersFake(const []));
      await missing.load();
      expect(missing.status, UserDetailsStatus.missing);

      final repository = _UsersFake(const [])
        ..failure = const UserProfileFailure(
          UserProfileFailureType.permissionDenied,
        );
      final denied = _detailsViewModel(repository);
      await denied.load();
      expect(denied.status, UserDetailsStatus.failure);
      expect(denied.errorMessage, 'You do not have permission to view users.');
    });
  });

  group('widgets', () {
    testWidgets('list renders search, filters, badges, rows and navigation', (
      tester,
    ) async {
      final viewModel = _listViewModel(
        _UsersFake([
          _user('1', 'Admin User', UserRole.admin),
          _user('2', 'Technician User', UserRole.technician),
          _user('3', 'Viewer User', UserRole.viewer, active: false),
        ]),
      );
      await viewModel.load();
      String? selectedId;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: MaterialApp(
            home: UserManagementScreen(
              onUserTap: (id) async {
                selectedId = id;
                return null;
              },
            ),
          ),
        ),
      );
      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('Search by name or email'), findsOneWidget);
      expect(find.text('Admin'), findsWidgets);
      expect(find.text('Technician'), findsWidgets);
      expect(find.text('Viewer'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Disabled'), findsWidgets);
      await tester.tap(find.text('Admin User'));
      expect(selectedId, '1');
      expect(tester.takeException(), isNull);
    });

    testWidgets('list no-result state resets filters', (tester) async {
      final viewModel = _listViewModel(
        _UsersFake([_user('1', 'One User', UserRole.viewer)]),
      );
      await viewModel.load();
      viewModel.updateQuery('missing');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: MaterialApp(
            home: UserManagementScreen(onUserTap: (_) async => null),
          ),
        ),
      );
      expect(
        find.text('No users match your search or filters.'),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset search and filters'));
      await tester.pump();
      expect(viewModel.hasFilters, isFalse);
      expect(viewModel.filteredUsers.single.name, 'One User');
    });

    testWidgets('details renders profile and friendly facilities', (
      tester,
    ) async {
      final repository = _UsersFake([
        _user(
          'target',
          'Target User',
          UserRole.technician,
          facilities: const ['site_1'],
          company: 'Bait Guard',
        ),
      ]);
      final viewModel = _detailsViewModel(repository);
      await viewModel.load();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const MaterialApp(home: UserDetailsScreen()),
        ),
      );
      expect(find.text('User Details'), findsOneWidget);
      expect(find.text('Target User'), findsOneWidget);
      expect(find.text('Technician'), findsOneWidget);
      expect(find.text('Bait Guard'), findsOneWidget);
      expect(find.text('Warehouse A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

UserManagementViewModel _listViewModel(
  _UsersFake repository, {
  UserRole role = UserRole.admin,
  bool active = true,
}) {
  return UserManagementViewModel(
    userRepository: repository,
    sessionController: _session(role, active),
  );
}

UserDetailsViewModel _detailsViewModel(
  _UsersFake repository, {
  UserRole role = UserRole.admin,
  bool active = true,
}) {
  return UserDetailsViewModel(
    userId: 'target',
    userRepository: repository,
    settingsRepository: _SettingsFake(),
    sessionController: _session(role, active),
  );
}

AppSessionController _session(UserRole role, bool active) =>
    AppSessionController()..establishSession(
      _user('current', 'Current Admin', role, active: active),
    );

AppUser _user(
  String id,
  String name,
  UserRole role, {
  bool active = true,
  String email = 'user@example.com',
  String? firstName,
  String? lastName,
  String? company,
  List<String> facilities = const [],
}) {
  return AppUser(
    id: id,
    name: name,
    email: email,
    role: role,
    isActive: active,
    siteAccessIds: facilities,
    firstName: firstName,
    lastName: lastName,
    company: company,
  );
}

class _UsersFake implements UserRepository {
  _UsersFake(this.users);
  final List<AppUser> users;
  int getUsersCalls = 0;
  final List<String> requestedIds = [];
  UserProfileFailure? failure;
  Completer<List<AppUser>>? completer;

  @override
  Future<List<AppUser>> getUsers() async {
    getUsersCalls++;
    if (failure case final value?) throw value;
    return completer?.future ?? users;
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    requestedIds.add(id);
    if (failure case final value?) throw value;
    return users.where((user) => user.id == id).firstOrNull;
  }

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

class _SettingsFake implements SettingsRepository {
  @override
  Future<List<SettingsFacilityOption>> getPermittedFacilities(
    List<String> permittedSiteIds,
  ) async {
    return [
      if (permittedSiteIds.contains('site_1'))
        const SettingsFacilityOption(
          id: 'site_1',
          name: 'Warehouse A',
          stationCount: 1,
          offlineStationCount: 0,
        ),
    ];
  }

  @override
  Future<String?> getFacilityDisplayName(String siteId) async => null;
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
