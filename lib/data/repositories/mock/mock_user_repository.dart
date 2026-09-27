import '../../../domain/models/app_user.dart';
import '../../../domain/models/manage_user_access_request.dart';
import '../../../domain/models/user_profile_failure.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/user_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockUserRepository implements UserRepository {
  final MockBaitGuardDataSource _dataSource;

  MockUserRepository(this._dataSource);

  @override
  Future<List<AppUser>> getUsers({String? siteId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _dataSource.users;
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _dataSource.users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _dataSource.updateUser(user);
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
    final current = await getUserById(uid);
    if (current == null) {
      throw StateError('User profile not found');
    }
    final updated = AppUser(
      id: current.id,
      name: '${firstName.trim()} ${lastName.trim()}'.trim(),
      email: current.email,
      role: current.role,
      isActive: current.isActive,
      siteAccessIds: current.siteAccessIds,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      jobTitle: jobTitle.trim().isEmpty ? null : jobTitle.trim(),
      department: department.trim().isEmpty ? null : department.trim(),
      phoneNumber: phone.trim().isEmpty ? null : phone.trim(),
      shortBio: bio.trim().isEmpty ? null : bio.trim(),
      company: current.company,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    _dataSource.updateUser(updated);
    return updated;
  }

  @override
  Future<AppUser> updateManagedUserAccess(
    ManageUserAccessRequest request,
  ) async {
    final reviewer = await getUserById(request.reviewerUid);
    final target = await getUserById(request.targetUserId);
    if (reviewer == null ||
        reviewer.role != UserRole.admin ||
        !reviewer.isActive) {
      throw const UserProfileFailure(UserProfileFailureType.permissionDenied);
    }
    if (target == null) {
      throw const UserProfileFailure(UserProfileFailureType.missing);
    }
    if (target.id == reviewer.id || target.role == UserRole.admin) {
      throw const UserProfileFailure(UserProfileFailureType.permissionDenied);
    }
    final facilities =
        request.facilityIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    if (request.role == UserRole.admin ||
        facilities.isEmpty ||
        facilities.length > 20) {
      throw const UserProfileFailure(UserProfileFailureType.permissionDenied);
    }
    final updated = target.copyWith(
      role: request.role,
      siteAccessIds: facilities,
      isActive: request.isActive,
      updatedAt: DateTime.now(),
    );
    _dataSource.updateUser(updated);
    return updated;
  }
}
