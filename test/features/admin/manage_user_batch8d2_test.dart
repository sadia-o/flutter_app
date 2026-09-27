import 'dart:async';

import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/data/repositories/firebase/firestore_user_repository.dart';
import 'package:baitguard/domain/models/administrator_contact.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/manage_user_access_request.dart';
import 'package:baitguard/domain/models/settings_facility_option.dart';
import 'package:baitguard/domain/models/user_profile_failure.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/models/user_settings.dart';
import 'package:baitguard/domain/repositories/settings_repository.dart';
import 'package:baitguard/domain/repositories/user_repository.dart';
import 'package:baitguard/features/admin/view_models/manage_user_view_model.dart';
import 'package:baitguard/features/admin/view_models/user_details_view_model.dart';
import 'package:baitguard/features/admin/views/manage_user_screen.dart';
import 'package:baitguard/features/admin/views/user_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('ManageUserViewModel', () {
    for (final role in [UserRole.technician, UserRole.viewer]) {
      test('active admin loads ${role.name} target and facilities', () async {
        final target = _user(
          'target',
          role,
          facilities: const ['site_1', 'legacy'],
        );
        final repository = _UserFake(target);
        final viewModel = _viewModel(repository);

        await viewModel.load();

        expect(viewModel.status, ManageUserStatus.ready);
        expect(viewModel.selectedRole, role);
        expect(viewModel.selectedActive, isTrue);
        expect(viewModel.selectedFacilityIds, {'site_1', 'legacy'});
        expect(
          viewModel.facilities.map((facility) => facility.name),
          containsAll(['Warehouse A', 'Unknown facility']),
        );
        expect(viewModel.isDirty, isFalse);
      });
    }

    for (final role in [UserRole.technician, UserRole.viewer]) {
      test('${role.name} reviewer is denied before target read', () async {
        final repository = _UserFake(_user('target', UserRole.viewer));
        final viewModel = _viewModel(repository, reviewerRole: role);
        await viewModel.load();
        expect(viewModel.status, ManageUserStatus.denied);
        expect(repository.getByIdCalls, 0);
      });
    }

    test(
      'disabled admin, missing session, and self target are denied',
      () async {
        final repository = _UserFake(_user('target', UserRole.viewer));
        await _viewModel(repository, reviewerActive: false).load();
        expect(repository.getByIdCalls, 0);

        final missing = ManageUserViewModel(
          targetUserId: 'target',
          userRepository: repository,
          settingsRepository: _SettingsFake(),
          sessionController: AppSessionController(),
        );
        await missing.load();
        expect(missing.status, ManageUserStatus.denied);

        final self = _viewModel(repository, targetId: 'admin');
        await self.load();
        expect(self.status, ManageUserStatus.denied);
      },
    );

    test('admin and missing targets cannot be managed', () async {
      final adminRepository = _UserFake(_user('target', UserRole.admin));
      final admin = _viewModel(adminRepository);
      await admin.load();
      expect(admin.status, ManageUserStatus.denied);

      final missing = _viewModel(_UserFake(null));
      await missing.load();
      expect(missing.status, ManageUserStatus.missing);
    });

    test(
      'role, facilities, and status drive dirty state and exact request',
      () async {
        final original = _user(
          'target',
          UserRole.viewer,
          facilities: const ['site_1'],
        );
        final repository = _UserFake(original);
        final session = _adminSession();
        final viewModel = _viewModel(repository, session: session);
        await viewModel.load();

        viewModel.selectRole(UserRole.technician);
        viewModel.toggleFacility('site_2');
        viewModel.selectStatus(false);
        expect(viewModel.isDirty, isTrue);
        expect(viewModel.willDisable, isTrue);
        expect(await viewModel.submit(), isTrue);

        final request = repository.lastRequest!;
        expect(request.reviewerUid, 'admin');
        expect(request.targetUserId, 'target');
        expect(request.role, UserRole.technician);
        expect(request.facilityIds.toSet(), {'site_1', 'site_2'});
        expect(request.isActive, isFalse);
        expect(viewModel.savedUser?.isActive, isFalse);
        expect(session.currentUser?.id, 'admin');
      },
    );

    test('no-change and empty facility submissions are prevented', () async {
      final repository = _UserFake(
        _user('target', UserRole.viewer, facilities: const ['site_1']),
      );
      final viewModel = _viewModel(repository);
      await viewModel.load();
      expect(await viewModel.submit(), isFalse);
      expect(repository.updateCalls, 0);

      viewModel.toggleFacility('site_1');
      expect(await viewModel.submit(), isFalse);
      expect(viewModel.facilityError, 'Select at least one facility.');
      expect(repository.updateCalls, 0);
    });

    test(
      'duplicate submit is prevented and form survives network failure',
      () async {
        final repository = _UserFake(
          _user('target', UserRole.viewer, facilities: const ['site_1']),
        )..updateCompleter = Completer<AppUser>();
        final viewModel = _viewModel(repository);
        await viewModel.load();
        viewModel.selectRole(UserRole.technician);
        final first = viewModel.submit();
        final duplicate = viewModel.submit();
        expect(repository.updateCalls, 1);
        expect(await duplicate, isFalse);
        repository.updateCompleter!.completeError(
          const UserProfileFailure(UserProfileFailureType.unavailable),
        );
        expect(await first, isFalse);
        expect(viewModel.selectedRole, UserRole.technician);
        expect(
          viewModel.errorMessage,
          'User changes could not be saved. Check your connection and try again.',
        );
      },
    );

    test('managed update payload contains only access fields', () {
      final marker = Object();
      final payload = FirestoreUserRepository.buildManagedAccessUpdate(
        role: UserRole.technician,
        facilityIds: const [' site_2 ', 'site_1', 'site_1'],
        isActive: false,
        updatedAt: marker,
      );
      expect(payload.keys, {'role', 'facilityIds', 'status', 'updatedAt'});
      expect(payload['role'], 'technician');
      expect(payload['facilityIds'], ['site_1', 'site_2']);
      expect(payload['status'], 'disabled');
      expect(payload['updatedAt'], same(marker));
      expect(payload, isNot(contains('email')));
      expect(payload, isNot(contains('displayName')));
    });

    test('admin role and invalid facility payloads are rejected', () {
      expect(
        () => FirestoreUserRepository.buildManagedAccessUpdate(
          role: UserRole.admin,
          facilityIds: const ['site_1'],
          isActive: true,
          updatedAt: Object(),
        ),
        throwsA(isA<UserProfileFailure>()),
      );
      expect(
        () => FirestoreUserRepository.buildManagedAccessUpdate(
          role: UserRole.viewer,
          facilityIds: const [],
          isActive: true,
          updatedAt: Object(),
        ),
        throwsA(isA<UserProfileFailure>()),
      );
    });
  });

  group('Manage User widgets and details entry point', () {
    testWidgets(
      'screen renders identity, allowed roles, facilities, and status',
      (tester) async {
        final viewModel = _viewModel(
          _UserFake(
            _user('target', UserRole.viewer, facilities: const ['site_1']),
          ),
        );
        await viewModel.load();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: viewModel,
            child: const MaterialApp(home: ManageUserScreen()),
          ),
        );
        expect(find.text('Manage User'), findsOneWidget);
        expect(find.text('Target User'), findsOneWidget);
        expect(find.text('Technician'), findsOneWidget);
        expect(find.text('Viewer'), findsWidgets);
        expect(find.text('Admin'), findsNothing);
        expect(find.text('Warehouse A'), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(find.text('Active'), findsWidgets);
        expect(find.text('Disabled'), findsOneWidget);
        expect(find.text('Save Changes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('disabling displays confirmation and Cancel preserves route', (
      tester,
    ) async {
      final viewModel = _viewModel(
        _UserFake(
          _user('target', UserRole.viewer, facilities: const ['site_1']),
        ),
      );
      await viewModel.load();
      viewModel.selectStatus(false);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const MaterialApp(home: ManageUserScreen()),
        ),
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Disable user access?'), findsOneWidget);
      expect(find.text('Disable User'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Manage User'), findsOneWidget);
      expect(viewModel.selectedActive, isFalse);
    });

    for (final role in [UserRole.technician, UserRole.viewer]) {
      testWidgets('details shows Manage User for ${role.name}', (tester) async {
        final repository = _UserFake(_user('target', role));
        final viewModel = UserDetailsViewModel(
          userId: 'target',
          userRepository: repository,
          settingsRepository: _SettingsFake(),
          sessionController: _adminSession(),
        );
        await viewModel.load();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: viewModel,
            child: MaterialApp(
              home: UserDetailsScreen(onManageUser: (_) async => false),
            ),
          ),
        );
        expect(find.text('Manage User'), findsOneWidget);
      });
    }

    testWidgets('details hides Manage User for Admin and self', (tester) async {
      final adminTarget = UserDetailsViewModel(
        userId: 'other-admin',
        userRepository: _UserFake(_user('other-admin', UserRole.admin)),
        settingsRepository: _SettingsFake(),
        sessionController: _adminSession(),
      );
      await adminTarget.load();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: adminTarget,
          child: const MaterialApp(home: UserDetailsScreen()),
        ),
      );
      expect(find.text('Manage User'), findsNothing);

      final self = UserDetailsViewModel(
        userId: 'admin',
        userRepository: _UserFake(_user('admin', UserRole.admin)),
        settingsRepository: _SettingsFake(),
        sessionController: _adminSession(),
      );
      await self.load();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: self,
          child: const MaterialApp(home: UserDetailsScreen()),
        ),
      );
      expect(find.text('Manage User'), findsNothing);
    });
  });
}

ManageUserViewModel _viewModel(
  _UserFake repository, {
  String targetId = 'target',
  UserRole reviewerRole = UserRole.admin,
  bool reviewerActive = true,
  AppSessionController? session,
}) {
  return ManageUserViewModel(
    targetUserId: targetId,
    userRepository: repository,
    settingsRepository: _SettingsFake(),
    sessionController:
        session ?? _adminSession(role: reviewerRole, active: reviewerActive),
  );
}

AppSessionController _adminSession({
  UserRole role = UserRole.admin,
  bool active = true,
}) {
  return AppSessionController()..establishSession(
    AppUser(
      id: 'admin',
      name: 'Current Admin',
      email: 'admin@example.com',
      role: role,
      isActive: active,
      siteAccessIds: const ['site_1', 'site_2'],
    ),
  );
}

AppUser _user(
  String id,
  UserRole role, {
  bool active = true,
  List<String> facilities = const ['site_1'],
}) {
  return AppUser(
    id: id,
    name: id == 'target' ? 'Target User' : 'Other Admin',
    email: '$id@example.com',
    role: role,
    isActive: active,
    siteAccessIds: facilities,
  );
}

class _UserFake implements UserRepository {
  _UserFake(this.target);
  AppUser? target;
  int getByIdCalls = 0;
  int updateCalls = 0;
  ManageUserAccessRequest? lastRequest;
  Completer<AppUser>? updateCompleter;

  @override
  Future<AppUser?> getUserById(String id) async {
    getByIdCalls++;
    return target?.id == id ? target : null;
  }

  @override
  Future<AppUser> updateManagedUserAccess(
    ManageUserAccessRequest request,
  ) async {
    updateCalls++;
    lastRequest = request;
    if (updateCompleter != null) return updateCompleter!.future;
    final current = target!;
    target = current.copyWith(
      role: request.role,
      siteAccessIds: request.facilityIds,
      isActive: request.isActive,
      updatedAt: DateTime.now(),
    );
    return target!;
  }

  @override
  Future<List<AppUser>> getUsers() async => [?target];
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
          stationCount: 2,
          offlineStationCount: 0,
        ),
      if (permittedSiteIds.contains('site_2'))
        const SettingsFacilityOption(
          id: 'site_2',
          name: 'Warehouse B',
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
