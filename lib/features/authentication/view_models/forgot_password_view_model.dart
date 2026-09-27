import 'package:flutter/foundation.dart';

import '../../../domain/models/auth_failure.dart';
import '../../../domain/repositories/auth_repository.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  ForgotPasswordViewModel(this._authRepository);

  final AuthRepository _authRepository;

  String _email = '';
  String? _emailError;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isDisposed = false;

  String get email => _email;
  String? get emailError => _emailError;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;

  void setEmail(String value) {
    _email = value;
    if (_emailError == null && _errorMessage == null) return;
    _emailError = null;
    _errorMessage = null;
    _notifySafely();
  }

  Future<bool> submit() => _send();

  Future<bool> resend() => _send();

  Future<bool> _send() async {
    if (_isLoading) return false;

    final normalizedEmail = _email.trim().toLowerCase();
    _emailError = _validateEmail(normalizedEmail);
    _errorMessage = null;
    if (_emailError != null) {
      _notifySafely();
      return false;
    }

    _isLoading = true;
    _notifySafely();

    try {
      await _authRepository.sendPasswordResetEmail(normalizedEmail);
      if (_isDisposed) return false;
      _email = normalizedEmail;
      _isSuccess = true;
      return true;
    } on AuthFailure catch (failure) {
      if (_isDisposed) return false;
      _errorMessage = switch (failure.type) {
        AuthFailureType.invalidEmail => 'Enter a valid email address.',
        AuthFailureType.network =>
          'Unable to connect. Check your internet connection and try again.',
        AuthFailureType.tooManyRequests =>
          'Too many reset attempts. Please wait and try again.',
        AuthFailureType.operationNotAllowed =>
          'Password reset is unavailable right now. Please contact an administrator.',
        _ => 'Unable to send reset instructions right now. Please try again.',
      };
      return false;
    } catch (_) {
      if (_isDisposed) return false;
      _errorMessage =
          'Unable to send reset instructions right now. Please try again.';
      return false;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email address is required.';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value)) return 'Enter a valid email address.';
    return null;
  }

  void _notifySafely() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
