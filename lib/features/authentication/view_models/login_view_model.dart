import 'package:flutter/foundation.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/models/auth_failure.dart';
import '../../../domain/models/user_profile_failure.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/repositories/login_preferences_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final AppSessionController _sessionController;
  final LoginPreferencesRepository _loginPreferencesRepository;

  LoginViewModel(
    this._authRepository,
    this._userRepository,
    this._sessionController,
    this._loginPreferencesRepository,
  );

  String _email = '';
  String _password = '';
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isDisposed = false;
  bool _hasInitializedPreferences = false;
  Future<void>? _pendingRememberedEmailClear;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  String get email => _email;
  String get password => _password;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get rememberMe => _rememberMe;
  bool get isLoading => _isLoading;

  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get generalError => _generalError;

  Future<void> initializeRememberedEmail() async {
    if (_hasInitializedPreferences || _isDisposed) return;
    _hasInitializedPreferences = true;
    try {
      final remembered = await _loginPreferencesRepository.load();
      if (_isDisposed) return;
      _rememberMe = remembered.enabled;
      _email = remembered.enabled ? remembered.email ?? '' : '';
      notifyListeners();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to load remembered login email: $error');
      }
    }
  }

  void setEmail(String value) {
    _email = value;
    if (_emailError != null) {
      _emailError = null;
      notifyListeners();
    }
  }

  void setPassword(String value) {
    _password = value;
    if (_passwordError != null) {
      _passwordError = null;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
    if (!_rememberMe) {
      _pendingRememberedEmailClear ??= _clearRememberedEmail();
    }
  }

  void clearErrors() {
    _emailError = null;
    _passwordError = null;
    _generalError = null;
    notifyListeners();
  }

  bool _validate() {
    bool isValid = true;
    clearErrors();

    final trimmedEmail = _email.trim();
    if (trimmedEmail.isEmpty) {
      _emailError = 'Email address is required.';
      isValid = false;
    } else if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      _emailError = 'Enter a valid email address.';
      isValid = false;
    }

    if (_password.isEmpty) {
      _passwordError = 'Password is required.';
      isValid = false;
    } else if (_password.length < 6) {
      _passwordError = 'Password must contain at least 6 characters.';
      isValid = false;
    }

    if (!isValid) {
      notifyListeners();
    }
    return isValid;
  }

  Future<bool> login() async {
    if (_isLoading || _isDisposed) return false;

    if (!_validate()) return false;

    _isLoading = true;
    _generalError = null;
    notifyListeners();

    try {
      final normalizedEmail = _email.trim().toLowerCase();
      _debug('stage=1 firebase_auth_sign_in start');
      final identity = await _authRepository.signIn(normalizedEmail, _password);
      _debug(
        'stage=1 firebase_auth_sign_in success '
        'currentUser=true uid=${identity.uid}',
      );
      _debug('stage=2 firestore_profile_read start uid=${identity.uid}');
      final user = await _userRepository.getUserById(identity.uid);
      if (_isDisposed) {
        await _signOutAfterProfileFailure();
        return false;
      }
      if (user == null) {
        _debug('stage=2 firestore_profile_read failure type=missing');
        await _rejectAuthenticatedIdentity(
          'Your account profile could not be found. Contact your administrator.',
        );
        return false;
      }
      if (user.id != identity.uid) {
        _debug('stage=3 app_user_parse failure type=uid_mismatch');
        await _rejectAuthenticatedIdentity(
          'Your account profile is incomplete. Contact your administrator.',
        );
        return false;
      }
      _debug('stage=3 app_user_parse success uid=${identity.uid}');
      if (!user.isActive) {
        _debug('stage=4 role_status_validation failure type=disabled');
        await _rejectAuthenticatedIdentity('Your account has been disabled.');
        return false;
      }
      _debug(
        'stage=4 role_status_validation success '
        'role=${user.role.name} uid=${identity.uid}',
      );

      _debug('stage=5 session_establishment start uid=${identity.uid}');
      _sessionController.establishSession(user);
      _debug(
        'stage=5 session_establishment success '
        'currentUser=${_sessionController.currentUser != null} '
        'uid=${_sessionController.currentUser?.id ?? 'none'}',
      );
      if (_rememberMe) {
        await _pendingRememberedEmailClear;
        _pendingRememberedEmailClear = null;
        await _saveRememberedEmail(normalizedEmail);
      } else {
        await (_pendingRememberedEmailClear ?? _clearRememberedEmail());
        _pendingRememberedEmailClear = null;
      }
      _password = '';
      return true;
    } on UserProfileFailure catch (failure) {
      _debug(
        'profile_pipeline failure type=${failure.type.name} '
        'currentUser=${_sessionController.currentUser != null}',
      );
      await _signOutAfterProfileFailure();
      _generalError = switch (failure.type) {
        UserProfileFailureType.missing =>
          'Your account profile could not be found. Contact your administrator.',
        UserProfileFailureType.malformed ||
        UserProfileFailureType.unknownRole ||
        UserProfileFailureType.unknownStatus =>
          'Your account profile is incomplete. Contact your administrator.',
        UserProfileFailureType.permissionDenied ||
        UserProfileFailureType.unauthenticated =>
          'Your account profile could not be accessed.',
        UserProfileFailureType.unavailable =>
          'Unable to connect. Check your internet connection and try again.',
      };
      return false;
    } on AuthFailure catch (e) {
      _debug(
        'stage=1 firebase_auth_sign_in failure '
        'type=${e.type.name} '
        'currentUser=${_sessionController.currentUser != null}',
      );
      _generalError = switch (e.type) {
        AuthFailureType.invalidCredentials => 'Email or password is incorrect.',
        AuthFailureType.invalidEmail => 'Enter a valid email address.',
        AuthFailureType.accountDisabled => 'Your account has been disabled.',
        AuthFailureType.network =>
          'Unable to connect. Check your internet connection and try again.',
        AuthFailureType.tooManyRequests =>
          'Too many login attempts. Please wait and try again.',
        AuthFailureType.operationNotAllowed || AuthFailureType.unknown =>
          'Unable to sign in right now. Please try again.',
        AuthFailureType.emailAlreadyInUse =>
          'Unable to sign in right now. Please try again.',
        AuthFailureType.weakPassword ||
        AuthFailureType.requiresRecentLogin ||
        AuthFailureType.noAuthenticatedUser =>
          'Unable to sign in right now. Please try again.',
      };
      return false;
    } catch (_) {
      _generalError = 'Unable to sign in right now. Please try again.';
      return false;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _rejectAuthenticatedIdentity(String message) async {
    await _signOutAfterProfileFailure();
    _generalError = message;
  }

  Future<void> _signOutAfterProfileFailure() async {
    try {
      await _authRepository.signOut();
      _debug('partial_session_cleanup sign_out=success');
    } catch (_) {
      _debug('partial_session_cleanup sign_out=failure');
      // Never establish a local application session for a rejected profile.
    }
  }

  void _debug(String message) {
    if (kDebugMode) debugPrint('[BaitGuard Login] $message');
  }

  Future<void> _saveRememberedEmail(String email) async {
    try {
      await _loginPreferencesRepository.saveRememberedEmail(email);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to save remembered login email: $error');
      }
    }
  }

  Future<void> _clearRememberedEmail() async {
    try {
      await _loginPreferencesRepository.clearRememberedEmail();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to clear remembered login email: $error');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
