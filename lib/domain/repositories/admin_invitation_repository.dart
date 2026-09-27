import '../models/create_admin_invitation_request.dart';

abstract class AdminInvitationRepository {
  Future<AdminInvitationConflict> findInvitationConflict(
    String normalizedEmail,
  );
  Future<void> createAdminInvitation(CreateAdminInvitationRequest request);
}
