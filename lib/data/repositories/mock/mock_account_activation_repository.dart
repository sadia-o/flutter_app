import '../../../domain/models/account_activation_failure.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/approved_access_invitation.dart';
import '../../../domain/repositories/account_activation_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockAccountActivationRepository implements AccountActivationRepository {
  MockAccountActivationRepository([MockBaitGuardDataSource? dataSource]);

  @override
  Future<ApprovedAccessInvitation>
  findApprovedInvitationForCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    throw const AccountActivationFailure(
      AccountActivationFailureType.unauthenticated,
    );
  }

  @override
  Future<AppUser> activateApprovedAccount({
    required ApprovedAccessInvitation invitation,
    required String firebaseUid,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    throw const AccountActivationFailure(
      AccountActivationFailureType.unauthenticated,
    );
  }
}
