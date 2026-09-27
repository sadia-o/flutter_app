class AuthenticatedIdentity {
  final String uid;
  final String? email;
  final bool emailVerified;

  const AuthenticatedIdentity({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });
}
