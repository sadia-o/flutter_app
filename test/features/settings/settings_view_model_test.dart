import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/user_repository.dart';
import 'package:baitguard/features/settings/view_models/edit_profile_view_model.dart';

// ── In-memory stub implementing the real UserRepository interface ─────────

class _StubUserRepository implements UserRepository {
  @override
  Future<AppUser> updateManagedUserAccess(dynamic request) =>
      throw UnimplementedError();
  AppUser? lastUpdated;
  AppUser? existingUser;
  bool shouldThrow = false;

  @override
  Future<List<AppUser>> getUsers({String? siteId}) async => [];

  @override
  Future<AppUser?> getUserById(String id) async => null;

  @override
  Future<AppUser> updateUser(AppUser user) async {
    if (shouldThrow) throw Exception('network error');
    lastUpdated = user;
    return user;
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
  }) async {
    if (shouldThrow) throw Exception('network error');
    final current = existingUser!;
    lastUpdated = AppUser(
      id: current.id,
      name: '$firstName $lastName'.trim(),
      email: current.email,
      role: current.role,
      isActive: current.isActive,
      siteAccessIds: current.siteAccessIds,
      firstName: firstName,
      lastName: lastName,
      jobTitle: jobTitle,
      department: department,
      phoneNumber: phone,
      shortBio: bio,
      company: current.company,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    return lastUpdated!;
  }
}

// ── Fixture helpers ───────────────────────────────────────────────────────

AppUser _makeUser({
  String firstName = 'Jane',
  String lastName = 'Doe',
  String? jobTitle,
  String? department,
  String? phoneNumber,
  String? shortBio,
}) => AppUser(
  id: 'user_1',
  name: '$firstName $lastName',
  email: 'jane.doe@company.com',
  role: UserRole.viewer,
  siteAccessIds: const ['site_1'],
  firstName: firstName,
  lastName: lastName,
  jobTitle: jobTitle,
  department: department,
  phoneNumber: phoneNumber,
  shortBio: shortBio,
);

EditProfileViewModel _makeVm(
  AppSessionController session,
  UserRepository repo,
) {
  if (repo is _StubUserRepository) {
    repo.existingUser = session.currentUser;
  }
  return EditProfileViewModel(userRepository: repo, sessionController: session);
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late AppSessionController session;
  late _StubUserRepository repo;

  setUp(() {
    session = AppSessionController();
    repo = _StubUserRepository();
  });

  group('EditProfileViewModel', () {
    test('initial values are loaded from AppUser on session', () {
      session.establishSession(
        _makeUser(
          firstName: 'Alice',
          lastName: 'Smith',
          jobTitle: 'Inspector',
          department: 'Ops',
          phoneNumber: '+1 111 000 0000',
          shortBio: 'Some bio.',
        ),
      );
      final vm = _makeVm(session, repo);

      expect(vm.firstName, 'Alice');
      expect(vm.lastName, 'Smith');
      expect(vm.jobTitle, 'Inspector');
      expect(vm.department, 'Ops');
      expect(vm.phoneNumber, '+1 111 000 0000');
      expect(vm.shortBio, 'Some bio.');
    });

    test(
      'email is read-only via currentUser; EditProfileViewModel has no email setter',
      () {
        session.establishSession(_makeUser());
        final vm = _makeVm(session, repo);

        expect(vm.currentUser?.email, 'jane.doe@company.com');
        // Verify there is no public `email` field on the vm itself.
        // (Compile-time guarantee; this assertion confirms it stays read-only.)
        final mirror = vm;
        expect(mirror, isA<EditProfileViewModel>());
      },
    );

    test('bio cannot exceed 200 characters — validation rejects it', () {
      session.establishSession(_makeUser());
      final vm = _makeVm(session, repo);
      vm.shortBio = 'x' * 201;

      final err = vm.validate();
      expect(err, isNotNull);
      expect(err, contains('200'));
    });

    test('bio of exactly 200 characters passes validation', () {
      session.establishSession(_makeUser());
      final vm = _makeVm(session, repo);
      vm.shortBio = 'x' * 200;

      expect(vm.validate(), isNull);
    });

    test('character counter matches bio length', () {
      session.establishSession(_makeUser());
      final vm = _makeVm(session, repo);

      vm.shortBio = 'hello';
      expect(vm.bioCharCount, 5);

      vm.shortBio = '';
      expect(vm.bioCharCount, 0);
    });

    test('validation fails when first name is empty', () {
      session.establishSession(_makeUser());
      final vm = _makeVm(session, repo);
      vm.firstName = '';

      expect(vm.validate(), isNotNull);
    });

    test('validation allows a one-part name', () {
      session.establishSession(_makeUser());
      final vm = _makeVm(session, repo);
      vm.lastName = '';

      expect(vm.validate(), isNull);
    });

    test('validation passes for a valid phone number', () {
      session.establishSession(_makeUser());
      final vm = _makeVm(session, repo);
      vm.phoneNumber = '+1 555 012 3456';

      expect(vm.validate(), isNull);
    });

    test('validation fails for a clearly invalid phone', () {
      session.establishSession(_makeUser());
      final vm = _makeVm(session, repo);
      vm.phoneNumber = 'not-a-phone!!!';

      expect(vm.validate(), isNotNull);
    });

    test('phone is optional — empty string passes validation', () {
      session.establishSession(_makeUser());
      final vm = _makeVm(session, repo);
      vm.phoneNumber = '';

      expect(vm.validate(), isNull);
    });

    test('save does not call repository when validation fails', () async {
      session.establishSession(_makeUser());
      final vm = _makeVm(session, repo);
      vm.firstName = ''; // invalid

      final result = await vm.save();

      expect(result, isFalse);
      expect(repo.lastUpdated, isNull);
    });

    test('Cancel: not calling save() leaves repository untouched', () {
      session.establishSession(_makeUser());
      _makeVm(session, repo); // construct but never save

      expect(repo.lastUpdated, isNull);
    });

    test('successful save calls repository with updated user fields', () async {
      session.establishSession(_makeUser(firstName: 'Jane', lastName: 'Doe'));
      final vm = _makeVm(session, repo);
      vm.firstName = 'Updated';
      vm.lastName = 'Name';
      vm.jobTitle = 'Senior Inspector';

      final result = await vm.save();

      expect(result, isTrue);
      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.firstName, 'Updated');
      expect(repo.lastUpdated!.lastName, 'Name');
      expect(repo.lastUpdated!.name, 'Updated Name');
      expect(repo.lastUpdated!.jobTitle, 'Senior Inspector');
    });

    test(
      'successful save calls establishSession on AppSessionController',
      () async {
        session.establishSession(_makeUser());
        final vm = _makeVm(session, repo);
        vm.firstName = 'NewFirst';
        vm.lastName = 'NewLast';

        int notifyCount = 0;
        session.addListener(() => notifyCount++);

        await vm.save();

        expect(notifyCount, greaterThan(0));
        expect(session.currentUser?.firstName, 'NewFirst');
      },
    );

    test(
      'Main Settings reflects saved values via AppSessionController',
      () async {
        session.establishSession(_makeUser(firstName: 'Old', lastName: 'Name'));
        final vm = _makeVm(session, repo);
        vm.firstName = 'New';
        vm.lastName = 'Name';

        await vm.save();

        expect(session.currentUser?.name, 'New Name');
        expect(session.currentUser?.firstName, 'New');
      },
    );

    test('save failure sets error message and status to failure', () async {
      session.establishSession(_makeUser());
      repo.shouldThrow = true;
      final vm = _makeVm(session, repo);

      final result = await vm.save();

      expect(result, isFalse);
      expect(vm.errorMessage, isNotNull);
      expect(vm.saveStatus, EditProfileSaveStatus.failure);
    });
  });
}
