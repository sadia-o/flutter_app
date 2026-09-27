import 'package:flutter/foundation.dart';
import '../../../domain/models/access_request.dart';
import '../../../domain/models/access_request_failure.dart';
import '../../../domain/repositories/access_request_repository.dart';

class RequestAccessViewModel extends ChangeNotifier {
  RequestAccessViewModel(this._accessRequestRepository);

  final AccessRequestRepository _accessRequestRepository;

  String _fullName = '';
  String _email = '';
  String _company = '';
  String _phone = '';
  String _department = '';
  String _message = '';

  String? _fullNameError;
  String? _emailError;
  String? _companyError;
  String? _phoneError;
  String? _departmentError;
  String? _messageError;
  String? _generalError;

  bool _isLoading = false;
  bool _isSubmitted = false;
  bool _isDisposed = false;

  String get fullName => _fullName;
  String get email => _email;
  String get company => _company;
  String get phone => _phone;
  String get department => _department;
  String get message => _message;

  String? get fullNameError => _fullNameError;
  String? get emailError => _emailError;
  String? get companyError => _companyError;
  String? get phoneError => _phoneError;
  String? get departmentError => _departmentError;
  String? get messageError => _messageError;
  String? get generalError => _generalError;

  bool get isLoading => _isLoading;
  bool get isSubmitted => _isSubmitted;

  void _onFieldEdited() {
    if (_isSubmitted) {
      _isSubmitted = false;
    }
    _generalError = null;
    _notifySafely();
  }

  void setFullName(String value) {
    _fullName = value;
    if (_fullNameError != null) {
      _fullNameError = null;
    }
    _onFieldEdited();
  }

  void setEmail(String value) {
    _email = value;
    if (_emailError != null) {
      _emailError = null;
    }
    _onFieldEdited();
  }

  void setCompany(String value) {
    _company = value;
    if (_companyError != null) {
      _companyError = null;
    }
    _onFieldEdited();
  }

  void setPhone(String value) {
    _phone = value;
    if (_phoneError != null) {
      _phoneError = null;
    }
    _onFieldEdited();
  }

  void setDepartment(String value) {
    _department = value;
    _departmentError = null;
    _onFieldEdited();
  }

  void setMessage(String value) {
    _message = value;
    _messageError = null;
    _onFieldEdited();
  }

  bool _validate() {
    bool isValid = true;
    _fullNameError = null;
    _emailError = null;
    _companyError = null;
    _phoneError = null;
    _departmentError = null;
    _messageError = null;
    _generalError = null;

    final trimmedFullName = _fullName.trim();
    if (trimmedFullName.isEmpty) {
      _fullNameError = 'Full name is required.';
      isValid = false;
    } else if (trimmedFullName.length < 2) {
      _fullNameError = 'Enter a valid full name.';
      isValid = false;
    } else if (trimmedFullName.length > 100) {
      _fullNameError = 'Full name must be 100 characters or fewer.';
      isValid = false;
    }

    final trimmedEmail = _email.trim();
    if (trimmedEmail.isEmpty) {
      _emailError = 'Company email is required.';
      isValid = false;
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmedEmail)) {
      _emailError = 'Enter a valid company email.';
      isValid = false;
    }

    final trimmedCompany = _company.trim();
    if (trimmedCompany.isEmpty) {
      _companyError = 'Company or organisation is required.';
      isValid = false;
    } else if (trimmedCompany.length < 2) {
      _companyError = 'Enter a valid company or organisation.';
      isValid = false;
    } else if (trimmedCompany.length > 120) {
      _companyError =
          'Company or organisation must be 120 characters or fewer.';
      isValid = false;
    }

    final trimmedPhone = _phone.trim();
    if (trimmedPhone.isEmpty) {
      _phoneError = 'Phone number is required.';
      isValid = false;
    } else {
      final digitsOnly = trimmedPhone.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
        _phoneError = 'Enter a valid phone number.';
        isValid = false;
      } else if (!RegExp(r'^[+\d\s().-]+$').hasMatch(trimmedPhone)) {
        _phoneError = 'Enter a valid phone number.';
        isValid = false;
      }
    }

    if (_department.trim().length > 100) {
      _departmentError = 'Department must be 100 characters or fewer.';
      isValid = false;
    }
    if (_message.trim().length > 500) {
      _messageError = 'Additional message must be 500 characters or fewer.';
      isValid = false;
    }

    if (!isValid) {
      _notifySafely();
    }
    return isValid;
  }

  Future<bool> submit() async {
    if (_isLoading || _isSubmitted || _isDisposed) return false;

    if (!_validate()) return false;

    _isLoading = true;
    _generalError = null;
    _notifySafely();

    try {
      final request = AccessRequest(
        fullName: _fullName.trim(),
        email: _email.trim().toLowerCase(),
        company: _company.trim(),
        phone: _phone.trim(),
        department: _department.trim(),
        message: _message.trim(),
        submittedAt: DateTime.now(),
      );

      await _accessRequestRepository.submitRequest(request);
      if (_isDisposed) return false;
      _isSubmitted = true;
      return true;
    } on AccessRequestFailure catch (failure) {
      if (_isDisposed) return false;
      _generalError = switch (failure.type) {
        AccessRequestFailureType.unavailable =>
          'Unable to submit your request. Check your internet connection and try again.',
        AccessRequestFailureType.permissionDenied ||
        AccessRequestFailureType.unauthenticated =>
          'Access requests are temporarily unavailable. Please try again later.',
        AccessRequestFailureType.timeout =>
          'The request took too long. Please try again.',
        AccessRequestFailureType.invalidData ||
        AccessRequestFailureType.missingIndex ||
        AccessRequestFailureType.notFound ||
        AccessRequestFailureType.alreadyReviewed ||
        AccessRequestFailureType.invalidRole ||
        AccessRequestFailureType.noFacilitySelected ||
        AccessRequestFailureType.duplicateApprovedInvitation ||
        AccessRequestFailureType.unknown =>
          'Unable to submit your request right now. Please try again.',
      };
      return false;
    } catch (_) {
      if (_isDisposed) return false;
      _generalError =
          'Unable to submit your request right now. Please try again.';
      return false;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
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
