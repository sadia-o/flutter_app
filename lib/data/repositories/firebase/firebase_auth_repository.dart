import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/auth_failure.dart';
import '../../../domain/models/authenticated_identity.dart';
import '../../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Future<AuthenticatedIdentity?> getCurrentIdentity() async {
    return _mapUser(_firebaseAuth.currentUser);
  }

  @override
  Stream<AuthenticatedIdentity?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  Future<AuthenticatedIdentity> signIn(String email, String password) async {
    try {
      _debug('firebase_auth_sign_in:start');
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final identity = _mapUser(credential.user);
      if (identity == null) {
        _debug('firebase_auth_sign_in:null_user currentUser=false');
        throw const AuthFailure(AuthFailureType.unknown);
      }
      _debug(
        'firebase_auth_sign_in:success currentUser=true uid=${identity.uid}',
      );
      return identity;
    } on FirebaseAuthException catch (error) {
      _debug(
        'firebase_auth_sign_in:failure code=${error.code} '
        'currentUser=${_firebaseAuth.currentUser != null} '
        'uid=${_firebaseAuth.currentUser?.uid ?? 'none'}',
      );
      throw _mapFailure(error);
    }
  }

  @override
  Future<AuthenticatedIdentity> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final identity = _mapUser(credential.user);
      if (identity == null) throw const AuthFailure(AuthFailureType.unknown);
      return identity;
    } on FirebaseAuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthFailure(AuthFailureType.noAuthenticatedUser);
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<AuthenticatedIdentity?> reloadCurrentIdentity() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    try {
      _debug('verification_check:start currentUser=true');
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;
      _debug(
        'verification_check:reload_complete '
        'currentUser=${refreshedUser != null} '
        'emailVerified=${refreshedUser?.emailVerified ?? false}',
      );
      return _mapUser(refreshedUser);
    } on FirebaseAuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> refreshCurrentUserToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthFailure(AuthFailureType.noAuthenticatedUser);
    }
    try {
      // Force Firebase Auth to mint a token containing the latest
      // email_verified claim before Firestore evaluates activation rules.
      await user.getIdToken(true);
      _debug('verification_check:forced_token_refresh_complete');
    } on FirebaseAuthException catch (error) {
      _debug('verification_check:token_refresh_failure code=${error.code}');
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
    } on FirebaseAuthException catch (error) {
      // Preserve account-discovery privacy if this code is returned by a
      // project that does not have email-enumeration protection enabled.
      if (error.code == 'user-not-found') return;
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.trim().isEmpty) {
      throw const AuthFailure(AuthFailureType.noAuthenticatedUser);
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  AuthenticatedIdentity? _mapUser(User? user) {
    if (user == null) return null;
    return AuthenticatedIdentity(
      uid: user.uid,
      email: user.email,
      emailVerified: user.emailVerified,
    );
  }

  AuthFailure _mapFailure(FirebaseAuthException error) {
    final type = switch (error.code) {
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => AuthFailureType.invalidCredentials,
      'invalid-email' => AuthFailureType.invalidEmail,
      'user-disabled' => AuthFailureType.accountDisabled,
      'network-request-failed' => AuthFailureType.network,
      'too-many-requests' => AuthFailureType.tooManyRequests,
      'operation-not-allowed' => AuthFailureType.operationNotAllowed,
      'weak-password' => AuthFailureType.weakPassword,
      'requires-recent-login' => AuthFailureType.requiresRecentLogin,
      'no-current-user' => AuthFailureType.noAuthenticatedUser,
      'email-already-in-use' => AuthFailureType.emailAlreadyInUse,
      _ => AuthFailureType.unknown,
    };
    return AuthFailure(type, error);
  }

  void _debug(String message) {
    if (kDebugMode) debugPrint('[BaitGuard Auth] $message');
  }
}
