import 'user_role.dart';

class CreateAdminInvitationRequest {
  const CreateAdminInvitationRequest({
    required this.fullName,
    required this.email,
    required this.company,
    required this.phone,
    required this.department,
    required this.role,
    required this.facilityIds,
    required this.reviewerUid,
  });

  final String fullName;
  final String email;
  final String company;
  final String phone;
  final String department;
  final UserRole role;
  final List<String> facilityIds;
  final String reviewerUid;
}

enum AdminInvitationConflict { none, pendingRequest, approvedUnused }
