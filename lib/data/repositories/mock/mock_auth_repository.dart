import '../../../domain/models/authenticated_identity.dart';
import '../../../domain/models/auth_failure.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockAuthRepository implements AuthRepository {
  final MockBaitGuardDataSource _dataSource;
  AuthenticatedIdentity? _currentIdentity;

  MockAuthRepository(this._dataSource);

  @override
  Future<AuthenticatedIdentity?> getCurrentIdentity() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentIdentity;
  }

  @override
  Stream<AuthenticatedIdentity?> authStateChanges() async* {
    yield _currentIdentity;
  }

  @override
  Future<AuthenticatedIdentity> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final user = _dataSource.authenticate(email, password);

    if (user == null) {
      throw const AuthFailure(AuthFailureType.invalidCredentials);
    }

    if (!user.isActive) {
      throw const AuthFailure(AuthFailureType.accountDisabled);
    }

    _currentIdentity = AuthenticatedIdentity(
      uid: user.id,
      email: user.email,
      emailVerified: true,
    );
    return _currentIdentity!;
  }

  @override
  Future<AuthenticatedIdentity> createAccount({
    required String email,
    required String password,
  }) async {
    _currentIdentity = AuthenticatedIdentity(
      uid: 'activation-user',
      email: email.trim().toLowerCase(),
      emailVerified: false,
    );
    return _currentIdentity!;
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AuthenticatedIdentity?> reloadCurrentIdentity() async =>
      _currentIdentity;

  @override
  Future<void> refreshCurrentUserToken() async {}

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentIdentity = null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
