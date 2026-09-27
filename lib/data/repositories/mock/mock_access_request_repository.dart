import '../../../domain/models/access_request.dart';
import '../../../domain/models/access_request_record.dart';
import '../../../domain/repositories/access_request_repository.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/models/access_request_failure.dart';
import '../../../domain/models/create_admin_invitation_request.dart';
import '../../../domain/repositories/admin_invitation_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockAccessRequestRepository
    implements AccessRequestRepository, AdminInvitationRepository {
  final MockBaitGuardDataSource _dataSource;

  MockAccessRequestRepository(this._dataSource);

  @override
  Future<void> submitRequest(AccessRequest request) async {
    await Future.delayed(const Duration(seconds: 1));
    _dataSource.addAccessRequest(request);
  }

  @override
  Future<AdminInvitationConflict> findInvitationConflict(String email) async {
    final normalized = email.trim().toLowerCase();
    final matching = _dataSource.accessRequests.where(
      (record) => record.request.normalizedEmail == normalized,
    );
    if (matching.any(
      (record) => record.status == AccessRequestStatus.pending,
    )) {
      return AdminInvitationConflict.pendingRequest;
    }
    if (matching.any(
      (record) =>
          record.status == AccessRequestStatus.approved &&
          record.request.activatedUid == null,
    )) {
      return AdminInvitationConflict.approvedUnused;
    }
    return AdminInvitationConflict.none;
  }

  @override
  Future<void> createAdminInvitation(
    CreateAdminInvitationRequest request,
  ) async {
    _dataSource.addAccessRequest(
      AccessRequest(
        fullName: request.fullName.trim(),
        email: request.email.trim().toLowerCase(),
        company: request.company.trim(),
        phone: request.phone.trim(),
        department: request.department.trim(),
        message: '',
        status: AccessRequestStatus.approved,
        reviewedBy: request.reviewerUid,
        assignedRole: request.role.name,
        assignedFacilityIds: request.facilityIds,
        approvalSource: 'admin',
      ),
    );
  }

  @override
  Future<List<AccessRequestRecord>> getPendingRequests({String? siteId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _dataSource.accessRequests
        .where((r) => r.status == AccessRequestStatus.pending)
        .toList();
  }

  @override
  Future<void> approveRequest({
    required String requestId,
    required String reviewerUid,
    required UserRole assignedRole,
    required List<String> assignedFacilityIds,
  }) async {
    if (assignedRole == UserRole.admin) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidRole);
    }
    if (assignedFacilityIds.isEmpty) {
      throw const AccessRequestFailure(
        AccessRequestFailureType.noFacilitySelected,
      );
    }
    _review(requestId);
  }

  @override
  Future<void> rejectRequest({
    required String requestId,
    required String reviewerUid,
    required String rejectionReason,
  }) async {
    _review(requestId);
  }

  void _review(String requestId) {
    final record = _dataSource.accessRequests
        .where((candidate) => candidate.id == requestId)
        .firstOrNull;
    if (record == null) {
      throw const AccessRequestFailure(AccessRequestFailureType.notFound);
    }
    if (record.status != AccessRequestStatus.pending) {
      throw const AccessRequestFailure(
        AccessRequestFailureType.alreadyReviewed,
      );
    }
    _dataSource.removeAccessRequest(requestId);
  }
}
