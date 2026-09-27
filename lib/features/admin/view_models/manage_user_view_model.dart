import 'package:flutter/foundation.dart';

import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/manage_user_access_request.dart';
import '../../../domain/models/settings_facility_option.dart';
import '../../../domain/models/user_profile_failure.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/user_repository.dart';

enum ManageUserStatus { initial, loading, ready, missing, denied, failure }

class ManageUserViewModel extends ChangeNotifier {
  ManageUserViewModel({
    required this.targetUserId,
    required UserRepository userRepository,
    required SettingsRepository settingsRepository,
    required AppSessionController sessionController,
  }) : _userRepository = userRepository,
       _settingsRepository = settingsRepository,
       _sessionController = sessionController;

  final String targetUserId;
  final UserRepository _userRepository;
  final SettingsRepository _settingsRepository;
  final AppSessionController _sessionController;

  ManageUserStatus _status = ManageUserStatus.initial;
  AppUser? _target;
  List<SettingsFacilityOption> _facilities = const [];
  UserRole? _selectedRole;
  Set<String> _selectedFacilityIds = {};
  bool _selectedActive = true;
  UserRole? _originalRole;
  Set<String> _originalFacilityIds = {};
  bool _originalActive = true;
  bool _submitting = false;
  bool _disposed = false;
  String? _errorMessage;
  String? _facilityError;
  AppUser? _savedUser;

  ManageUserStatus get status => _status;
  AppUser? get target => _target;
  List<SettingsFacilityOption> get facilities => _facilities;
  UserRole? get selectedRole => _selectedRole;
  Set<String> get selectedFacilityIds => Set.unmodifiable(_selectedFacilityIds);
  bool get selectedActive => _selectedActive;
  bool get isSubmitting => _submitting;
  String? get errorMessage => _errorMessage;
  String? get facilityError => _facilityError;
  AppUser? get savedUser => _savedUser;
  bool get willDisable => _originalActive && !_selectedActive;
  bool get isDirty =>
      _selectedRole != _originalRole ||
      _selectedActive != _originalActive ||
      !setEquals(_selectedFacilityIds, _originalFacilityIds);
  bool get canSubmit =>
      _status == ManageUserStatus.ready &&
      !_submitting &&
      isDirty &&
      _selectedRole != null &&
      _selectedRole != UserRole.admin &&
      _selectedFacilityIds.isNotEmpty &&
      _selectedFacilityIds.length <= 20;

  bool get isAuthorized {
    final reviewer = _sessionController.currentUser;
    return reviewer != null &&
        reviewer.role == UserRole.admin &&
        reviewer.isActive &&
        reviewer.id != targetUserId;
  }

  Future<void> load() async {
    if (_status == ManageUserStatus.loading || _disposed) return;
    if (!isAuthorized) {
      _deny();
      return;
    }
    _status = ManageUserStatus.loading;
    _errorMessage = null;
    _notify();
    try {
      final reviewer = _sessionController.currentUser!;
      final target = await _userRepository.getUserById(targetUserId);
      if (_disposed) return;
      if (target == null) {
        _status = ManageUserStatus.missing;
        _errorMessage = 'This user profile is no longer available.';
        return;
      }
      if (target.id == reviewer.id || target.role == UserRole.admin) {
        _deny();
        return;
      }
      final known = await _settingsRepository.getPermittedFacilities(
        reviewer.siteAccessIds,
      );
      if (_disposed) return;
      final byId = {for (final facility in known) facility.id: facility};
      _facilities = List.unmodifiable([
        ...known,
        for (final id in target.siteAccessIds)
          if (!byId.containsKey(id))
            SettingsFacilityOption(
              id: id,
              name: 'Unknown facility',
              stationCount: 0,
              offlineStationCount: 0,
            ),
      ]);
      _target = target;
      _selectedRole = target.role;
      _selectedFacilityIds = target.siteAccessIds.toSet();
      _selectedActive = target.isActive;
      _captureOriginal();
      _status = ManageUserStatus.ready;
    } on UserProfileFailure catch (failure) {
      if (_disposed) return;
      if (failure.type == UserProfileFailureType.missing) {
        _status = ManageUserStatus.missing;
        _errorMessage = 'This user profile is no longer available.';
      } else if (failure.type == UserProfileFailureType.permissionDenied) {
        _status = ManageUserStatus.denied;
        _errorMessage = 'You do not have permission to manage this user.';
      } else {
        _status = ManageUserStatus.failure;
        _errorMessage =
            'User details could not be loaded. Check your connection and try again.';
      }
    } catch (_) {
      if (_disposed) return;
      _status = ManageUserStatus.failure;
      _errorMessage =
          'User details could not be loaded. Check your connection and try again.';
    } finally {
      _notify();
    }
  }

  void selectRole(UserRole role) {
    if (role == UserRole.admin || _submitting || _selectedRole == role) return;
    _selectedRole = role;
    _errorMessage = null;
    _notify();
  }

  void toggleFacility(String id) {
    if (_submitting) return;
    final updated = {..._selectedFacilityIds};
    if (!updated.remove(id)) updated.add(id);
    _selectedFacilityIds = updated;
    _facilityError = null;
    _errorMessage = null;
    _notify();
  }

  void selectStatus(bool isActive) {
    if (_submitting || _selectedActive == isActive) return;
    _selectedActive = isActive;
    _errorMessage = null;
    _notify();
  }

  Future<bool> submit() async {
    if (_submitting || _disposed) return false;
    if (!isAuthorized || _target == null) {
      _errorMessage = 'This account cannot be managed here.';
      _notify();
      return false;
    }
    if (!isDirty) {
      _errorMessage = 'No changes to save.';
      _notify();
      return false;
    }
    if (_selectedFacilityIds.isEmpty) {
      _facilityError = 'Select at least one facility.';
      _notify();
      return false;
    }
    if (_selectedFacilityIds.length > 20) {
      _facilityError = 'Select no more than 20 facilities.';
      _notify();
      return false;
    }
    final role = _selectedRole;
    if (role == null || role == UserRole.admin) {
      _errorMessage = 'Select Technician or Viewer.';
      _notify();
      return false;
    }
    final reviewer = _sessionController.currentUser!;
    _submitting = true;
    _errorMessage = null;
    _facilityError = null;
    _notify();
    try {
      final updated = await _userRepository.updateManagedUserAccess(
        ManageUserAccessRequest(
          reviewerUid: reviewer.id,
          targetUserId: targetUserId,
          role: role,
          facilityIds: _selectedFacilityIds.toList(growable: false),
          isActive: _selectedActive,
        ),
      );
      if (_disposed) return false;
      _target = updated;
      _savedUser = updated;
      _selectedRole = updated.role;
      _selectedFacilityIds = updated.siteAccessIds.toSet();
      _selectedActive = updated.isActive;
      _captureOriginal();
      return true;
    } on UserProfileFailure catch (failure) {
      if (_disposed) return false;
      _errorMessage = switch (failure.type) {
        UserProfileFailureType.permissionDenied ||
        UserProfileFailureType.unauthenticated =>
          'You do not have permission to manage this user.',
        UserProfileFailureType.missing =>
          'This user profile is no longer available.',
        UserProfileFailureType.unavailable =>
          'User changes could not be saved. Check your connection and try again.',
        _ => 'User changes could not be saved. Please try again.',
      };
      return false;
    } catch (_) {
      if (_disposed) return false;
      _errorMessage = 'User changes could not be saved. Please try again.';
      return false;
    } finally {
      if (!_disposed) {
        _submitting = false;
        notifyListeners();
      }
    }
  }

  void _captureOriginal() {
    _originalRole = _selectedRole;
    _originalFacilityIds = {..._selectedFacilityIds};
    _originalActive = _selectedActive;
  }

  void _deny() {
    _status = ManageUserStatus.denied;
    _errorMessage = 'This account cannot be managed here.';
    _notify();
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
