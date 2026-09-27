enum AccessRequestFailureType {
  permissionDenied,
  unavailable,
  timeout,
  invalidData,
  unauthenticated,
  missingIndex,
  notFound,
  alreadyReviewed,
  invalidRole,
  noFacilitySelected,
  duplicateApprovedInvitation,
  unknown,
}

class AccessRequestFailure implements Exception {
  const AccessRequestFailure(this.type, [this.technicalCause]);

  final AccessRequestFailureType type;
  final Object? technicalCause;
}
