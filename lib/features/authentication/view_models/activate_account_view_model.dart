import 'package:flutter/foundation.dart';

import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/account_activation_failure.dart';
import '../../../domain/models/auth_failure.dart';
import '../../../domain/repositories/account_activation_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/user_repository.dart';

enum ActivateAccountStage { form, verification, activated }

class ActivateAccountViewModel extends ChangeNotifier {
  ActivateAccountViewModel({
    required AuthRepository authRepository,
    required AccountActivationRepository activationRepository,
    required AppSessionController sessionController,
    UserRepository? userRepository,
  }) : _authRepository = authRepository,
       _activationRepository = activationRepository,
       _sessionController = sessionController,
       _userRepository = userRepository;

  final AuthRepository _authRepository;
  final AccountActivationRepository _activationRepository;
  final AppSessionController _sessionController;
  final UserRepository? _userRepository;

  String email = '';
  String password = '';
  String confirmation = '';
  String? emailError;
  String? passwordError;
  String? confirmationError;
  String? errorMessage;
  bool obscurePassword = true;
  bool obscureConfirmation = true;
  bool isLoading = false;
  bool _disposed = false;
  ActivateAccountStage stage = ActivateAccountStage.form;

  bool get hasMinimumLength => password.length >= 8;
  bool get hasUppercase => password.contains(RegExp('[A-Z]'));
  bool get hasNumber => password.contains(RegExp('[0-9]'));
  bool get hasSpecialCharacter =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]'));

  void setEmail(String value) {
    email = value;
    emailError = null;
    errorMessage = null;
    notifyListeners();
  }

  void setPassword(String value) {
    password = value;
    passwordError = null;
    errorMessage = null;
    notifyListeners();
  }

  void setConfirmation(String value) {
    confirmation = value;
    confirmationError = null;
    notifyListeners();
  }

  void togglePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmation() {
    obscureConfirmation = !obscureConfirmation;
    notifyListeners();
  }

  Future<void> initialize() async {
    final identity = await _authRepository.getCurrentIdentity();
    if (_disposed || identity == null) return;
    email = identity.email ?? '';
    stage = ActivateAccountStage.verification;
    notifyListeners();
    if (identity.emailVerified) await checkVerification();
  }

  bool _validate() {
    final normalized = email.trim().toLowerCase();
    emailError = normalized.isEmpty
        ? 'Approved email is required.'
        : !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized)
        ? 'Enter a valid email address.'
        : null;
    passwordError = password.isEmpty
        ? 'Password is required.'
        : !(hasMinimumLength &&
              hasUppercase &&
              hasNumber &&
              hasSpecialCharacter)
        ? 'Use at least 8 characters, uppercase, number, and special character.'
        : null;
    confirmationError = confirmation != password
        ? 'Passwords do not match.'
        : null;
    return emailError == null &&
        passwordError == null &&
        confirmationError == null;
  }

  Future<bool> submit() async {
    if (isLoading || _disposed) return false;
    if (!_validate()) {
      notifyListeners();
      return false;
    }
    return _run(() async {
      try {
        await _authRepository.createAccount(
          email: email.trim().toLowerCase(),
          password: password,
        );
      } on AuthFailure catch (failure) {
        if (failure.type != AuthFailureType.emailAlreadyInUse) rethrow;
        await _authRepository.signIn(email.trim().toLowerCase(), password);
      }
      password = '';
      confirmation = '';
      final identity = await _authRepository.getCurrentIdentity();
      if (identity?.emailVerified == true) {
        return _activate(identity!.uid);
      }
      await _authRepository.sendEmailVerification();
      stage = ActivateAccountStage.verification;
      return true;
    });
  }

  Future<bool> resendVerification() => _run(() async {
    await _authRepository.sendEmailVerification();
    return true;
  });

  Future<bool> checkVerification() async {
    if (isLoading || _disposed) return false;
    return _run(() async {
      _debug('verification_check:start');
      final identity = await _authRepository.reloadCurrentIdentity();
      _debug(
        'verification_check:reload_complete '
        'currentUser=${identity != null} '
        'emailVerified=${identity?.emailVerified ?? false}',
      );
      if (identity == null || !identity.emailVerified) {
        throw const AccountActivationFailure(
          AccountActivationFailureType.notVerified,
        );
      }
      await _authRepository.refreshCurrentUserToken();
      _debug('verification_check:token_refresh_complete');
      return _activate(identity.uid);
    });
  }

  Future<bool> _activate(String uid) async {
    final existingProfile = await _userRepository?.getUserById(uid);
    if (existingProfile != null) {
      if (existingProfile.role.name == 'admin') {
        throw const AccountActivationFailure(
          AccountActivationFailureType.invalidInvitation,
        );
      }
      _sessionController.establishSession(existingProfile);
      stage = ActivateAccountStage.activated;
      return true;
    }
    _debug('invitation_lookup:start');
    final invitation = await _activationRepository
        .findApprovedInvitationForCurrentUser();
    final user = await _activationRepository.activateApprovedAccount(
      invitation: invitation,
      firebaseUid: uid,
    );
    if (user.role.name == 'admin') {
      throw const AccountActivationFailure(
        AccountActivationFailureType.invalidInvitation,
      );
    }
    _sessionController.establishSession(user);
    stage = ActivateAccountStage.activated;
    return true;
  }

  Future<void> abandon() async {
    if (stage != ActivateAccountStage.activated) {
      await _authRepository.signOut();
    }
  }

  Future<bool> _run(Future<bool> Function() action) async {
    if (isLoading || _disposed) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on AuthFailure catch (failure) {
      errorMessage = switch (failure.type) {
        AuthFailureType.emailAlreadyInUse =>
          'An account already exists for this email. Sign in to continue activation.',
        AuthFailureType.weakPassword => 'Choose a stronger password.',
        AuthFailureType.invalidEmail => 'Enter a valid email address.',
        AuthFailureType.tooManyRequests =>
          'Too many attempts. Please wait and try again.',
        AuthFailureType.network =>
          'Unable to connect. Check your internet connection and try again.',
        AuthFailureType.invalidCredentials =>
          'The account password is incorrect.',
        _ => 'Unable to activate your account right now.',
      };
      return false;
    } on AccountActivationFailure catch (failure) {
      _debug('activation_failure:type=${failure.type.name}');
      errorMessage = switch (failure.type) {
        AccountActivationFailureType.notVerified =>
          'Your email has not been verified yet.',
        AccountActivationFailureType.noInvitation =>
          'No approved access invitation was found for this verified email.',
        AccountActivationFailureType.multipleInvitations =>
          'Multiple approved invitations were found. Contact your administrator.',
        AccountActivationFailureType.alreadyActivated ||
        AccountActivationFailureType.profileAlreadyExists =>
          'This invitation has already been used. Please log in.',
        AccountActivationFailureType.invalidInvitation =>
          'Your approved access information is incomplete. Contact your administrator.',
        AccountActivationFailureType.permissionDenied =>
          'Account activation could not be authorized.',
        AccountActivationFailureType.network =>
          'Unable to connect. Check your internet connection and try again.',
        _ => 'Unable to activate your account right now.',
      };
      if (failure.type == AccountActivationFailureType.noInvitation) {
        await _authRepository.signOut();
      }
      return false;
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void _debug(String message) {
    if (kDebugMode) debugPrint('[BaitGuard Activation] $message');
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
