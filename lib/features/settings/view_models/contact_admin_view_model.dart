import 'package:flutter/foundation.dart';

import '../../../domain/models/administrator_contact.dart';
import '../../../domain/repositories/settings_repository.dart';

class ContactAdminViewModel extends ChangeNotifier {
  static const int maxMessageLength = 500;

  final SettingsRepository _repository;
  final String userId;

  AdministratorContact? _administrator;
  String message = '';
  bool _isLoading = false;
  bool _isSending = false;
  bool _isDisposed = false;
  String? _errorMessage;
  int _successEventId = 0;

  ContactAdminViewModel({
    required SettingsRepository repository,
    required this.userId,
  }) : _repository = repository;

  AdministratorContact? get administrator => _administrator;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  int get successEventId => _successEventId;
  int get characterCount => message.length;

  Future<void> load() async {
    if (_isLoading || _administrator != null || _isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final administrator = await _repository.getAdministratorContact(userId);
      if (_isDisposed) return;
      _administrator = administrator;
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = 'Unable to load administrator details.';
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void updateMessage(String value) {
    message = value;
    notifyListeners();
  }

  String? validate() {
    if (message.trim().isEmpty) {
      return 'Enter a message for your administrator.';
    }
    if (message.length > maxMessageLength) {
      return 'Message must be $maxMessageLength characters or fewer.';
    }
    if (_administrator == null) {
      return 'Administrator details are unavailable.';
    }
    return null;
  }

  Future<bool> send() async {
    if (_isSending || _isDisposed) return false;
    final validationError = validate();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.sendAdministratorMessage(
        userId: userId,
        administratorId: _administrator!.id,
        message: message.trim(),
      );
      if (_isDisposed) return false;
      message = '';
      _successEventId++;
      return true;
    } catch (_) {
      if (_isDisposed) return false;
      _errorMessage = 'Unable to send message. Please try again.';
      return false;
    } finally {
      if (!_isDisposed) {
        _isSending = false;
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
