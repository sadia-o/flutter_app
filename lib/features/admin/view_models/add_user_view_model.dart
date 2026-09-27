import 'package:flutter/foundation.dart';

import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/access_request_failure.dart';
import '../../../domain/models/create_admin_invitation_request.dart';
import '../../../domain/models/settings_facility_option.dart';
import '../../../domain/models/user_profile_failure.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/admin_invitation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/user_repository.dart';

class AddUserViewModel extends ChangeNotifier {
  AddUserViewModel({
    required AdminInvitationRepository invitationRepository,
    required UserRepository userRepository,
    required SettingsRepository settingsRepository,
    required AppSessionController sessionController,
  }) : _invitationRepository = invitationRepository,
       _userRepository = userRepository,
       _settingsRepository = settingsRepository,
       _sessionController = sessionController;

  final AdminInvitationRepository _invitationRepository;
  final UserRepository _userRepository;
  final SettingsRepository _settingsRepository;
  final AppSessionController _sessionController;

  String fullName = '';
  String email = '';
  String company = '';
  String phone = '';
  String department = '';
  UserRole? selectedRole;
  final Set<String> _selectedFacilityIds = {};
  List<SettingsFacilityOption> facilities = const [];

  String? fullNameError;
  String? emailError;
  String? companyError;
  String? phoneError;
  String? departmentError;
  String? roleError;
  String? facilityError;
  String? errorMessage;
  bool isLoadingFacilities = false;
  bool isSubmitting = false;
  bool _disposed = false;

  Set<String> get selectedFacilityIds => Set.unmodifiable(_selectedFacilityIds);
  bool get isAuthorized {
    final user = _sessionController.currentUser;
    return user != null && user.role == UserRole.admin && user.isActive;
  }

  Future<void> loadFacilities() async {
    if (!isAuthorized || isLoadingFacilities || facilities.isNotEmpty) return;
    isLoadingFacilities = true;
    _notify();
    try {
      final admin = _sessionController.currentUser!;
      facilities = List.unmodifiable(
        await _settingsRepository.getPermittedFacilities(admin.siteAccessIds),
      );
    } catch (_) {
      errorMessage = 'Unable to load facilities right now.';
    } finally {
      if (!_disposed) {
        isLoadingFacilities = false;
        notifyListeners();
      }
    }
  }

  void selectRole(UserRole role) {
    if (role == UserRole.admin || isSubmitting) return;
    selectedRole = role;
    roleError = null;
    _notify();
  }

  void toggleFacility(String id) {
    if (isSubmitting || !facilities.any((facility) => facility.id == id)) {
      return;
    }
    if (!_selectedFacilityIds.add(id)) _selectedFacilityIds.remove(id);
    facilityError = null;
    _notify();
  }

  bool validate() {
    final name = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedCompany = company.trim();
    final normalizedPhone = phone.trim();
    fullNameError = name.isEmpty
        ? 'Full name is required.'
        : name.length < 2 || name.length > 100
        ? 'Full name must be between 2 and 100 characters.'
        : null;
    emailError = normalizedEmail.isEmpty
        ? 'Email address is required.'
        : normalizedEmail.length > 254 ||
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)
        ? 'Enter a valid email address.'
        : null;
    companyError = normalizedCompany.isEmpty
        ? 'Company is required.'
        : normalizedCompany.length < 2 || normalizedCompany.length > 120
        ? 'Company must be between 2 and 120 characters.'
        : null;
    phoneError = !_validPhone(normalizedPhone)
        ? 'Enter a valid phone number.'
        : null;
    departmentError = department.trim().length > 100
        ? 'Department must be 100 characters or fewer.'
        : null;
    roleError = selectedRole == null ? 'Select a role.' : null;
    facilityError = _selectedFacilityIds.isEmpty
        ? 'Select at least one facility.'
        : _selectedFacilityIds.length > 20
        ? 'Select no more than 20 facilities.'
        : null;
    _notify();
    return [
      fullNameError,
      emailError,
      companyError,
      phoneError,
      departmentError,
      roleError,
      facilityError,
    ].every((error) => error == null);
  }

  Future<bool> submit() async {
    if (isSubmitting || _disposed || !isAuthorized) {
      if (!isAuthorized) {
        errorMessage = 'You do not have permission to create user invitations.';
        _notify();
      }
      return false;
    }
    if (!validate()) return false;
    isSubmitting = true;
    errorMessage = null;
    _notify();
    final admin = _sessionController.currentUser!;
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final users = await _userRepository.getUsers();
      if (users.any(
        (user) => user.email.trim().toLowerCase() == normalizedEmail,
      )) {
        errorMessage = 'A user with this email already exists.';
        return false;
      }
      final conflict = await _invitationRepository.findInvitationConflict(
        normalizedEmail,
      );
      if (conflict == AdminInvitationConflict.pendingRequest) {
        errorMessage =
            'A pending access request already exists for this email.';
        return false;
      }
      if (conflict == AdminInvitationConflict.approvedUnused) {
        errorMessage =
            'An unused approved invitation already exists for this email.';
        return false;
      }
      await _invitationRepository.createAdminInvitation(
        CreateAdminInvitationRequest(
          fullName: fullName.trim(),
          email: normalizedEmail,
          company: company.trim(),
          phone: phone.trim(),
          department: department.trim(),
          role: selectedRole!,
          facilityIds: _selectedFacilityIds.toList(growable: false),
          reviewerUid: admin.id,
        ),
      );
      return !_disposed;
    } on AccessRequestFailure catch (failure) {
      errorMessage = switch (failure.type) {
        AccessRequestFailureType.permissionDenied ||
        AccessRequestFailureType.unauthenticated =>
          'You do not have permission to create user invitations.',
        AccessRequestFailureType.unavailable ||
        AccessRequestFailureType.timeout =>
          'Invitation could not be created. Check your connection and try again.',
        _ => 'Invitation could not be created. Please try again.',
      };
      return false;
    } on UserProfileFailure catch (failure) {
      errorMessage = failure.type == UserProfileFailureType.permissionDenied
          ? 'You do not have permission to create user invitations.'
          : 'Invitation could not be created. Check your connection and try again.';
      return false;
    } catch (_) {
      errorMessage = 'Invitation could not be created. Please try again.';
      return false;
    } finally {
      if (!_disposed) {
        isSubmitting = false;
        notifyListeners();
      }
    }
  }

  static bool _validPhone(String value) {
    if (value.length < 7 || value.length > 30) return false;
    if (!RegExp(r'^[+\d\s\-()]+$').hasMatch(value)) return false;
    return value.replaceAll(RegExp(r'\D'), '').length >= 7;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
