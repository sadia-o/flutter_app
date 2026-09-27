import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/data/repositories/firebase/firestore_access_request_repository.dart';
import 'package:baitguard/data/repositories/firebase/firestore_account_activation_repository.dart';
import 'package:baitguard/domain/models/account_activation_failure.dart';
import 'package:baitguard/domain/models/administrator_contact.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/create_admin_invitation_request.dart';
import 'package:baitguard/domain/models/settings_facility_option.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/models/user_settings.dart';
import 'package:baitguard/domain/repositories/admin_invitation_repository.dart';
import 'package:baitguard/domain/repositories/settings_repository.dart';
import 'package:baitguard/domain/repositories/user_repository.dart';
import 'package:baitguard/features/admin/view_models/add_user_view_model.dart';
import 'package:baitguard/features/admin/views/add_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('active admin loads friendly facility options', () async {
    final viewModel = _viewModel();
    await viewModel.loadFacilities();
    expect(viewModel.facilities.single.name, 'Warehouse A');
    expect(viewModel.facilities.single.id, 'site_1');
  });

  for (final role in [UserRole.viewer, UserRole.technician]) {
    test('${role.name} cannot load or submit', () async {
      final invitations = _InvitationFake();
      final viewModel = _viewModel(
        sessionRole: role,
        invitationRepository: invitations,
      );
      await viewModel.loadFacilities();
      expect(viewModel.facilities, isEmpty);
      expect(await viewModel.submit(), isFalse);
      expect(invitations.createCalls, 0);
    });
  }

  test('validation requires fields, role, and facility', () {
    final viewModel = _viewModel();
    expect(viewModel.validate(), isFalse);
    expect(viewModel.fullNameError, 'Full name is required.');
    expect(viewModel.emailError, 'Email address is required.');
    expect(viewModel.companyError, 'Company is required.');
    expect(viewModel.phoneError, 'Enter a valid phone number.');
    expect(viewModel.roleError, 'Select a role.');
    expect(viewModel.facilityError, 'Select at least one facility.');
  });

  test('valid submission is normalized and preserves admin session', () async {
    final invitations = _InvitationFake();
    final session = _adminSession();
    final original = session.currentUser;
    final viewModel = _viewModel(
      session: session,
      invitationRepository: invitations,
    );
    await _completeValidForm(viewModel);
    viewModel.department = '  ';

    expect(await viewModel.submit(), isTrue);
    final request = invitations.created!;
    expect(request.fullName, 'Invited User');
    expect(request.email, 'invited@example.com');
    expect(request.department, '');
    expect(request.role, UserRole.technician);
    expect(request.facilityIds, ['site_1']);
    expect(request.reviewerUid, 'admin-uid');
    expect(identical(session.currentUser, original), isTrue);
  });

  test('existing user and invitation conflicts are blocked safely', () async {
    final existing = _viewModel(
      users: _UsersFake([
        _user('existing', 'Existing', UserRole.viewer, 'invited@example.com'),
      ]),
    );
    await _completeValidForm(existing);
    expect(await existing.submit(), isFalse);
    expect(existing.errorMessage, 'A user with this email already exists.');

    for (final conflict in [
      AdminInvitationConflict.pendingRequest,
      AdminInvitationConflict.approvedUnused,
    ]) {
      final repository = _InvitationFake()..conflict = conflict;
      final viewModel = _viewModel(invitationRepository: repository);
      await _completeValidForm(viewModel);
      expect(await viewModel.submit(), isFalse);
      expect(repository.createCalls, 0);
    }
  });

  test('Firestore repository creates exact approved admin schema', () async {
    Map<String, Object?>? written;
    final repository = FirestoreAccessRequestRepository.withDependencies(
      writeDocument: (data) async => written = data,
      readPendingDocuments: () async => const [],
      readInvitationConflicts: (_) async => const [],
    );
    await repository.createAdminInvitation(
      const CreateAdminInvitationRequest(
        fullName: 'Invited User',
        email: 'INVITED@EXAMPLE.COM',
        company: 'Trinode',
        phone: '+923001234567',
        department: '',
        role: UserRole.viewer,
        facilityIds: ['site_1', 'site_1'],
        reviewerUid: 'admin-uid',
      ),
    );

    expect(written?['email'], 'invited@example.com');
    expect(written?['normalizedEmail'], 'invited@example.com');
    expect(written?['status'], 'approved');
    expect(written?['approvalSource'], 'admin');
    expect(written?['message'], '');
    expect(written?['department'], '');
    expect(written?['assignedRole'], 'viewer');
    expect(written?['assignedFacilityIds'], ['site_1']);
    expect(written?['reviewedBy'], 'admin-uid');
    expect(written?['activatedUid'], isNull);
    expect(written?['activatedAt'], isNull);
    expect(written?.keys, isNot(contains('password')));
    expect(written?.keys, isNot(contains('token')));
    expect(written?.keys, isNot(contains('uid')));
  });

  test(
    'rejected history does not block while pending and approved do',
    () async {
      final repository = FirestoreAccessRequestRepository.withDependencies(
        writeDocument: (_) async {},
        readPendingDocuments: () async => const [],
        readInvitationConflicts: (_) async => const [
          AccessRequestDocumentData(
            id: 'rejected',
            data: {'status': 'rejected', 'activatedUid': null},
          ),
        ],
      );
      expect(
        await repository.findInvitationConflict('USER@EXAMPLE.COM'),
        AdminInvitationConflict.none,
      );
    },
  );

  test(
    'activation accepts request and admin sources but rejects arbitrary source',
    () {
      Map<String, dynamic> data(String source) => {
        'fullName': 'Invited User',
        'normalizedEmail': 'invited@example.com',
        'company': 'Trinode',
        'department': '',
        'phone': '+923001234567',
        'status': 'approved',
        'assignedRole': 'technician',
        'assignedFacilityIds': ['site_1'],
        'approvalSource': source,
      };

      expect(
        FirestoreAccountActivationRepository.mapInvitation(
          'request-1',
          data('request'),
        ).assignedRole,
        UserRole.technician,
      );
      expect(
        FirestoreAccountActivationRepository.mapInvitation(
          'request-2',
          data('admin'),
        ).assignedRole,
        UserRole.technician,
      );
      expect(
        () => FirestoreAccountActivationRepository.mapInvitation(
          'request-3',
          data('other'),
        ),
        throwsA(isA<AccountActivationFailure>()),
      );
    },
  );

  testWidgets('Add User screen renders form and validation safely', (
    tester,
  ) async {
    final viewModel = _viewModel();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(home: AddUserScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add User'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Technician'), findsOneWidget);
    expect(find.text('Viewer'), findsOneWidget);
    expect(find.text('Warehouse A'), findsOneWidget);
    expect(find.text('Create Invitation'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _completeValidForm(AddUserViewModel viewModel) async {
  await viewModel.loadFacilities();
  viewModel.fullName = '  Invited User ';
  viewModel.email = ' INVITED@EXAMPLE.COM ';
  viewModel.company = ' Trinode ';
  viewModel.phone = '+923001234567';
  viewModel.selectRole(UserRole.technician);
  viewModel.toggleFacility('site_1');
}

AddUserViewModel _viewModel({
  UserRole sessionRole = UserRole.admin,
  AppSessionController? session,
  _InvitationFake? invitationRepository,
  _UsersFake? users,
}) => AddUserViewModel(
  invitationRepository: invitationRepository ?? _InvitationFake(),
  userRepository: users ?? _UsersFake(const []),
  settingsRepository: _SettingsFake(),
  sessionController:
      session ??
      (AppSessionController()..establishSession(
        _user('admin-uid', 'Admin User', sessionRole, 'admin@example.com'),
      )),
);

AppSessionController _adminSession() => AppSessionController()
  ..establishSession(
    _user('admin-uid', 'Admin User', UserRole.admin, 'admin@example.com'),
  );

AppUser _user(String id, String name, UserRole role, String email) => AppUser(
  id: id,
  name: name,
  email: email,
  role: role,
  siteAccessIds: const ['site_1'],
);

class _InvitationFake implements AdminInvitationRepository {
  AdminInvitationConflict conflict = AdminInvitationConflict.none;
  int createCalls = 0;
  CreateAdminInvitationRequest? created;

  @override
  Future<AdminInvitationConflict> findInvitationConflict(String email) async =>
      conflict;

  @override
  Future<void> createAdminInvitation(
    CreateAdminInvitationRequest request,
  ) async {
    createCalls++;
    created = request;
  }
}

class _UsersFake implements UserRepository {
  _UsersFake(this.users);
  final List<AppUser> users;

  @override
  Future<List<AppUser>> getUsers() async => users;
  @override
  Future<AppUser?> getUserById(String id) async => null;
  @override
  Future<AppUser> updateUser(AppUser user) => throw UnimplementedError();
  @override
  Future<AppUser> updateManagedUserAccess(dynamic request) =>
      throw UnimplementedError();
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

class _SettingsFake implements SettingsRepository {
  @override
  Future<List<SettingsFacilityOption>> getPermittedFacilities(
    List<String> permittedSiteIds,
  ) async => const [
    SettingsFacilityOption(
      id: 'site_1',
      name: 'Warehouse A',
      stationCount: 4,
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
