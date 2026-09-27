import 'user_role.dart';

class ApprovedAccessInvitation {
  const ApprovedAccessInvitation({
    required this.requestId,
    required this.fullName,
    required this.email,
    required this.company,
    required this.department,
    required this.phone,
    required this.assignedRole,
    required this.assignedFacilityIds,
  });

  final String requestId;
  final String fullName;
  final String email;
  final String company;
  final String department;
  final String phone;
  final UserRole assignedRole;
  final List<String> assignedFacilityIds;
}
