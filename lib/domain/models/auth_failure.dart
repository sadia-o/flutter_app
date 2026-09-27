enum AuthFailureType {
  invalidCredentials,
  invalidEmail,
  accountDisabled,
  network,
  tooManyRequests,
  operationNotAllowed,
  weakPassword,
  requiresRecentLogin,
  noAuthenticatedUser,
  emailAlreadyInUse,
  unknown,
}

class AuthFailure implements Exception {
  final AuthFailureType type;
  final Object? technicalCause;

  const AuthFailure(this.type, [this.technicalCause]);

  @override
  String toString() => 'AuthFailure(type: \$type, cause: \$technicalCause)';
}
