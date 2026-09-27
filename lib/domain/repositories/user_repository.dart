import '../models/app_user.dart';
import '../models/manage_user_access_request.dart';

abstract class UserRepository {
  Future<List<AppUser>> getUsers();
  Future<AppUser?> getUserById(String id);
  Future<AppUser> updateUser(AppUser user);
  Future<AppUser> updateOwnProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required String department,
    required String phone,
    required String bio,
  });

  Future<AppUser> updateManagedUserAccess(ManageUserAccessRequest request) {
    throw UnsupportedError('Managed-user access updates are not supported.');
  }
}
