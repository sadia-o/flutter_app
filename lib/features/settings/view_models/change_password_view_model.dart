import 'package:flutter/foundation.dart';

import '../../../domain/models/auth_failure.dart';
import '../../../domain/repositories/auth_repository.dart';

enum PasswordStrength { weak, medium, strong }

class ChangePasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  String currentPassword = '';
  String newPassword = '';
  String confirmPassword = '';

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isSaving = false;
  bool _isDisposed = false;
  String? _errorMessage;

  ChangePasswordViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository;

  bool get showCurrentPassword => _showCurrentPassword;
  bool get showNewPassword => _showNewPassword;
  bool get showConfirmPassword => _showConfirmPassword;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool get hasMinimumLength => newPassword.length >= 8;
  bool get hasUppercase => newPassword.contains(RegExp(r'[A-Z]'));
  bool get hasNumber => newPassword.contains(RegExp(r'[0-9]'));
  bool get hasSpecialCharacter =>
      newPassword.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=]'));

  PasswordStrength get strength {
    final score = [
      hasMinimumLength,
      hasUppercase,
      hasNumber,
      hasSpecialCharacter,
    ].where((rule) => rule).length;
    if (score >= 4) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  double get strengthProgress => switch (strength) {
    PasswordStrength.weak => 0.33,
    PasswordStrength.medium => 0.66,
    PasswordStrength.strong => 1,
  };

  void updateCurrentPassword(String value) {
    currentPassword = value;
  }

  void updateNewPassword(String value) {
    newPassword = value;
    notifyListeners();
  }

  void updateConfirmPassword(String value) {
    confirmPassword = value;
  }

  void toggleCurrentPasswordVisibility() {
    _showCurrentPassword = !_showCurrentPassword;
    notifyListeners();
  }

  void toggleNewPasswordVisibility() {
    _showNewPassword = !_showNewPassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _showConfirmPassword = !_showConfirmPassword;
    notifyListeners();
  }

  String? validate() {
    if (currentPassword.isEmpty) return 'Current password is required.';
    if (newPassword.isEmpty) return 'New password is required.';
    if (!hasMinimumLength) {
      return 'New password must be at least 8 characters.';
    }
    if (!hasUppercase) {
      return 'New password must include an uppercase letter.';
    }
    if (!hasNumber) return 'New password must include a number.';
    if (!hasSpecialCharacter) {
      return 'New password must include a special character.';
    }
    if (confirmPassword.isEmpty) return 'Confirm your new password.';
    if (newPassword != confirmPassword) return 'New passwords do not match.';
    return null;
  }

  Future<bool> submit() async {
    if (_isSaving || _isDisposed) return false;
    final validationError = validate();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (_isDisposed) return false;
      currentPassword = '';
      newPassword = '';
      confirmPassword = '';
      return true;
    } on AuthFailure catch (failure) {
      if (_isDisposed) return false;
      _errorMessage = switch (failure.type) {
        AuthFailureType.invalidCredentials =>
          'The current password is incorrect.',
        AuthFailureType.weakPassword => 'Choose a stronger password.',
        AuthFailureType.requiresRecentLogin ||
        AuthFailureType.noAuthenticatedUser =>
          'Your session has expired. Please sign in again.',
        AuthFailureType.accountDisabled =>
          'Your Bait Guard account has been disabled. Contact an administrator.',
        AuthFailureType.tooManyRequests =>
          'Too many attempts. Please wait and try again.',
        AuthFailureType.network =>
          'Unable to connect. Check your internet connection and try again.',
        _ => 'Unable to change your password right now. Please try again.',
      };
      return false;
    } catch (_) {
      if (_isDisposed) return false;
      _errorMessage =
          'Unable to change your password right now. Please try again.';
      return false;
    } finally {
      if (!_isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
