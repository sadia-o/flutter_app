import '../models/app_user.dart';
import '../models/approved_access_invitation.dart';

abstract class AccountActivationRepository {
  Future<ApprovedAccessInvitation> findApprovedInvitationForCurrentUser();

  Future<AppUser> activateApprovedAccount({
    required ApprovedAccessInvitation invitation,
    required String firebaseUid,
  });
}
