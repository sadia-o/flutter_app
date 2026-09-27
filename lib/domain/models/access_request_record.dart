import 'access_request.dart';

class AccessRequestRecord {
  final String id;
  final AccessRequest request;
  final AccessRequestStatus status;

  // We derive submittedAt from the request to avoid duplication.
  DateTime? get submittedAt => request.submittedAt;

  const AccessRequestRecord({
    required this.id,
    required this.request,
    required this.status,
  });
}
