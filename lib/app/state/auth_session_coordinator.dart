import 'package:flutter/foundation.dart';

import '../../domain/models/auth_failure.dart';
import '../../domain/models/user_profile_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import 'app_session_controller.dart';

enum SessionRestorationStatus {
  initial,
  restoring,
  authenticated,
  unauthenticated,
}

class AuthSessionCoordinator extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final AppSessionController _sessionController;

  SessionRestorationStatus _status = SessionRestorationStatus.initial;
  bool _isLoggingOut = false;
  bool _initializeStarted = false;
  String? _logoutErrorMessage;

  AuthSessionCoordinator({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    required AppSessionController sessionController,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       _sessionController = sessionController;

  SessionRestorationStatus get status => _status;
  bool get restorationComplete =>
      _status == SessionRestorationStatus.authenticated ||
      _status == SessionRestorationStatus.unauthenticated;
  bool get isLoggingOut => _isLoggingOut;
  String? get logoutErrorMessage => _logoutErrorMessage;

  Future<void> initialize() async {
    if (_initializeStarted) return;
    _initializeStarted = true;
    _status = SessionRestorationStatus.restoring;

    try {
      _debug('restoration_identity:start');
      final identity = await _authRepository.getCurrentIdentity();
      if (identity == null) {
        _debug('restoration_identity:none currentUser=false');
        _sessionController.clearSession();
        _status = SessionRestorationStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _debug('restoration_profile:start uid=${identity.uid}');
      final profile = await _userRepository.getUserById(identity.uid);
      if (profile == null || profile.id != identity.uid || !profile.isActive) {
        _debug(
          'restoration_profile:rejected '
          'type=${profile == null
              ? 'missing'
              : profile.id != identity.uid
              ? 'uid_mismatch'
              : 'disabled'} '
          'uid=${identity.uid}',
        );
        await _rejectRestoration();
        return;
      }

      _sessionController.establishSession(profile);
      _debug(
        'restoration_session:success '
        'currentUser=${_sessionController.currentUser != null} '
        'uid=${_sessionController.currentUser?.id ?? 'none'}',
      );
      _status = SessionRestorationStatus.authenticated;
      notifyListeners();
    } on UserProfileFailure catch (failure) {
      _debug('restoration_profile:failure type=${failure.type.name}');
      if (failure.type == UserProfileFailureType.missing ||
          failure.type == UserProfileFailureType.malformed ||
          failure.type == UserProfileFailureType.unknownRole ||
          failure.type == UserProfileFailureType.unknownStatus) {
        await _rejectRestoration();
      } else {
        _sessionController.clearSession();
        _status = SessionRestorationStatus.unauthenticated;
        notifyListeners();
      }
    } on AuthFailure {
      _debug('restoration_identity:domain_failure');
      _sessionController.clearSession();
      _status = SessionRestorationStatus.unauthenticated;
      notifyListeners();
    } catch (_) {
      _sessionController.clearSession();
      _status = SessionRestorationStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    if (_isLoggingOut) return false;
    _isLoggingOut = true;
    _logoutErrorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _sessionController.clearSession();
      _status = SessionRestorationStatus.unauthenticated;
      return true;
    } catch (_) {
      _logoutErrorMessage = 'Unable to log out right now. Please try again.';
      return false;
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  Future<void> _rejectRestoration() async {
    try {
      await _authRepository.signOut();
    } catch (_) {
      // The application session remains cleared even if remote sign-out fails.
    }
    _sessionController.clearSession();
    _status = SessionRestorationStatus.unauthenticated;
    notifyListeners();
  }

  void _debug(String message) {
    if (kDebugMode) debugPrint('[BaitGuard Session] $message');
  }
}
