import '../models/authenticated_identity.dart';

abstract class AuthRepository {
  Future<AuthenticatedIdentity?> getCurrentIdentity();
  Stream<AuthenticatedIdentity?> authStateChanges();
  Future<AuthenticatedIdentity> signIn(String email, String password);
  Future<AuthenticatedIdentity> createAccount({
    required String email,
    required String password,
  }) => throw UnsupportedError('Account activation is not supported.');
  Future<void> sendEmailVerification() =>
      throw UnsupportedError('Email verification is not supported.');
  Future<AuthenticatedIdentity?> reloadCurrentIdentity() =>
      throw UnsupportedError('Identity reload is not supported.');
  Future<void> refreshCurrentUserToken() =>
      throw UnsupportedError('Token refresh is not supported.');
  Future<void> sendPasswordResetEmail(String email);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> signOut();
}
