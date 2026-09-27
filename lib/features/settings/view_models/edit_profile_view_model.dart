import 'package:flutter/foundation.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/user_profile_failure.dart';

enum EditProfileSaveStatus { idle, saving, success, failure }

class EditProfileViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final AppSessionController _sessionController;
  final String assignedFacilityName;

  // Mutable form state
  String firstName;
  String lastName;
  String jobTitle;
  String department;
  String phoneNumber;
  String shortBio;

  EditProfileSaveStatus _saveStatus = EditProfileSaveStatus.idle;
  String? _errorMessage;

  static const int maxBioLength = 200;

  EditProfileViewModel({
    required UserRepository userRepository,
    required AppSessionController sessionController,
    this.assignedFacilityName = 'None',
  }) : _userRepository = userRepository,
       _sessionController = sessionController,
       firstName =
           sessionController.currentUser?.firstName ??
           _splitFirstName(sessionController.currentUser?.name ?? ''),
       lastName =
           sessionController.currentUser?.lastName ??
           _splitLastName(sessionController.currentUser?.name ?? ''),
       jobTitle = sessionController.currentUser?.jobTitle ?? '',
       department = sessionController.currentUser?.department ?? '',
       phoneNumber = sessionController.currentUser?.phoneNumber ?? '',
       shortBio = sessionController.currentUser?.shortBio ?? '';

  AppUser? get currentUser => _sessionController.currentUser;
  EditProfileSaveStatus get saveStatus => _saveStatus;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _saveStatus == EditProfileSaveStatus.saving;
  int get bioCharCount => shortBio.length;

  // Splits "John Anderson" → "John"
  static String _splitFirstName(String fullName) {
    final normalized = fullName.trim();
    if (normalized.isEmpty) return '';
    return normalized.split(RegExp(r'\s+')).first;
  }

  // Splits "John Anderson" → "Anderson"
  static String _splitLastName(String fullName) {
    final normalized = fullName.trim();
    if (normalized.isEmpty) return '';
    final parts = normalized.split(RegExp(r'\s+'));
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  /// Returns null if valid, or a human-readable error string.
  String? validate() {
    if (firstName.trim().isEmpty) return 'First name is required.';
    if (firstName.trim().length > 50) {
      return 'First name must be 50 characters or fewer.';
    }
    if (lastName.trim().length > 50) {
      return 'Last name must be 50 characters or fewer.';
    }
    if (jobTitle.trim().length > 80) {
      return 'Job title must be 80 characters or fewer.';
    }
    if (department.trim().length > 80) {
      return 'Department must be 80 characters or fewer.';
    }
    if (phoneNumber.trim().length > 30) {
      return 'Phone number must be 30 characters or fewer.';
    }
    if (phoneNumber.trim().isNotEmpty &&
        !_isReasonablePhone(phoneNumber.trim())) {
      return 'Enter a valid phone number.';
    }
    if (shortBio.length > maxBioLength) {
      return 'Short bio must be $maxBioLength characters or fewer.';
    }
    return null;
  }

  bool _isReasonablePhone(String phone) {
    // Accepts +, digits, spaces, dashes, parens. At least 7 digits.
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 7) return false;
    return RegExp(r'^[\+\d\s\-\(\)]+$').hasMatch(phone);
  }

  Future<bool> save() async {
    if (isSaving) return false;
    final validationError = validate();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    final user = currentUser;
    if (user == null) return false;

    _saveStatus = EditProfileSaveStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedUser = await _userRepository.updateOwnProfile(
        uid: user.id,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        jobTitle: jobTitle.trim(),
        department: department.trim(),
        phone: phoneNumber.trim(),
        bio: shortBio.trim(),
      );

      // Synchronise the session so dashboard names and Settings header update.
      _sessionController.establishSession(savedUser);

      _saveStatus = EditProfileSaveStatus.success;
      notifyListeners();
      return true;
    } on UserProfileFailure catch (failure) {
      _errorMessage = switch (failure.type) {
        UserProfileFailureType.unauthenticated =>
          'Your session has expired. Please sign in again.',
        UserProfileFailureType.permissionDenied =>
          'Your profile changes could not be authorized. Please sign in again or contact your administrator.',
        UserProfileFailureType.unavailable =>
          'Unable to connect. Check your internet connection and try again.',
        _ => 'Unable to save your profile right now. Please try again.',
      };
      _saveStatus = EditProfileSaveStatus.failure;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage =
          'Unable to save your profile right now. Please try again.';
      _saveStatus = EditProfileSaveStatus.failure;
      notifyListeners();
      return false;
    }
  }
}
