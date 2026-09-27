enum AccountActivationFailureType {
  notVerified,
  noInvitation,
  multipleInvitations,
  alreadyActivated,
  invalidInvitation,
  profileAlreadyExists,
  permissionDenied,
  unauthenticated,
  network,
  timeout,
  missingIndex,
  unknown,
}

class AccountActivationFailure implements Exception {
  const AccountActivationFailure(this.type, [this.cause]);

  final AccountActivationFailureType type;
  final Object? cause;
}
