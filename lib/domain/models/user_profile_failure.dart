enum UserProfileFailureType {
  missing,
  malformed,
  unknownRole,
  unknownStatus,
  unauthenticated,
  permissionDenied,
  unavailable,
}

class UserProfileFailure implements Exception {
  final UserProfileFailureType type;
  final Object? technicalCause;

  const UserProfileFailure(this.type, [this.technicalCause]);
}
