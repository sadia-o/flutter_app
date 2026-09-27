import '../models/access_request.dart';
import '../models/access_request_record.dart';
import '../models/user_role.dart';

abstract class AccessRequestRepository {
  Future<void> submitRequest(AccessRequest request);

  Future<List<AccessRequestRecord>> getPendingRequests({String? siteId});

  Future<void> approveRequest({
    required String requestId,
    required String reviewerUid,
    required UserRole assignedRole,
    required List<String> assignedFacilityIds,
  });

  Future<void> rejectRequest({
    required String requestId,
    required String reviewerUid,
    required String rejectionReason,
  });
}
