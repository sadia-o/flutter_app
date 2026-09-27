enum AccessRequestStatus { pending, approved, rejected }

class AccessRequest {
  const AccessRequest({
    this.requestId,
    required this.fullName,
    required this.email,
    required this.company,
    required this.phone,
    String? department,
    String? message,
    this.status = AccessRequestStatus.pending,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.assignedRole,
    this.assignedFacilityIds = const [],
    this.approvalSource,
    this.activatedAt,
    this.activatedUid,
  }) : department = department ?? '',
       message = message ?? '';

  final String? requestId;
  final String fullName;
  final String email;
  final String company;
  final String phone;
  final String department;
  final String message;
  final AccessRequestStatus status;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? assignedRole;
  final List<String> assignedFacilityIds;
  final String? approvalSource;
  final DateTime? activatedAt;
  final String? activatedUid;

  String get normalizedEmail => email.trim().toLowerCase();
}
