import 'user_role.dart';

class ManageUserAccessRequest {
  ManageUserAccessRequest({
    required this.reviewerUid,
    required this.targetUserId,
    required this.role,
    required List<String> facilityIds,
    required this.isActive,
  }) : facilityIds = List.unmodifiable(facilityIds);

  final String reviewerUid;
  final String targetUserId;
  final UserRole role;
  final List<String> facilityIds;
  final bool isActive;
}
