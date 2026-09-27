import 'package:flutter/foundation.dart';

import '../../../domain/models/access_request_failure.dart';
import '../../../domain/models/access_request_record.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/settings_facility_option.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/access_request_repository.dart';
import '../../../domain/repositories/settings_repository.dart';

class ReviewAccessRequestViewModel extends ChangeNotifier {
  ReviewAccessRequestViewModel({
    required this.request,
    required AppUser reviewer,
    required AccessRequestRepository accessRequestRepository,
    required SettingsRepository settingsRepository,
  }) : _reviewer = reviewer,
       _accessRequestRepository = accessRequestRepository,
       _settingsRepository = settingsRepository;

  final AccessRequestRecord request;
  final AppUser _reviewer;
  final AccessRequestRepository _accessRequestRepository;
  final SettingsRepository _settingsRepository;

  List<SettingsFacilityOption> _facilities = const [];
  final Set<String> _selectedFacilityIds = {};
  UserRole? _selectedRole;
  String _rejectionReason = '';
  String? _roleError;
  String? _facilityError;
  String? _reasonError;
  String? _errorMessage;
  bool _isLoadingFacilities = false;
  bool _isSubmitting = false;
  bool _isDisposed = false;

  List<SettingsFacilityOption> get facilities => _facilities;
  Set<String> get selectedFacilityIds => Set.unmodifiable(_selectedFacilityIds);
  UserRole? get selectedRole => _selectedRole;
  String get rejectionReason => _rejectionReason;
  String? get roleError => _roleError;
  String? get facilityError => _facilityError;
  String? get reasonError => _reasonError;
  String? get errorMessage => _errorMessage;
  bool get isLoadingFacilities => _isLoadingFacilities;
  bool get isSubmitting => _isSubmitting;

  Future<void> loadFacilities() async {
    if (_isLoadingFacilities || _facilities.isNotEmpty || _isDisposed) return;
    _isLoadingFacilities = true;
    _notify();
    try {
      _facilities = List.unmodifiable(
        await _settingsRepository.getPermittedFacilities(
          _reviewer.siteAccessIds,
        ),
      );
    } catch (_) {
      _errorMessage = 'Unable to load facilities right now.';
    } finally {
      if (!_isDisposed) {
        _isLoadingFacilities = false;
        notifyListeners();
      }
    }
  }

  void selectRole(UserRole role) {
    if (role == UserRole.admin || _isSubmitting) return;
    _selectedRole = role;
    _roleError = null;
    _errorMessage = null;
    _notify();
  }

  void toggleFacility(String facilityId) {
    if (_isSubmitting ||
        !_facilities.any((facility) => facility.id == facilityId)) {
      return;
    }
    if (!_selectedFacilityIds.add(facilityId)) {
      _selectedFacilityIds.remove(facilityId);
    }
    _facilityError = null;
    _errorMessage = null;
    _notify();
  }

  void setRejectionReason(String value) {
    _rejectionReason = value;
    _reasonError = null;
    _errorMessage = null;
    _notify();
  }

  Future<bool> approve() async {
    if (_isSubmitting || _isDisposed) return false;
    _roleError = _selectedRole == null ? 'Select a valid user role.' : null;
    _facilityError = _selectedFacilityIds.isEmpty
        ? 'Select at least one facility.'
        : null;
    if (_roleError != null || _facilityError != null) {
      _notify();
      return false;
    }
    return _submit(
      () => _accessRequestRepository.approveRequest(
        requestId: request.id,
        reviewerUid: _reviewer.id,
        assignedRole: _selectedRole!,
        assignedFacilityIds: _selectedFacilityIds.toList(growable: false),
      ),
    );
  }

  Future<bool> reject() async {
    if (_isSubmitting || _isDisposed) return false;
    final reason = _rejectionReason.trim();
    if (reason.length > 300) {
      _reasonError = 'Rejection reason must be 300 characters or fewer.';
      _notify();
      return false;
    }
    return _submit(
      () => _accessRequestRepository.rejectRequest(
        requestId: request.id,
        reviewerUid: _reviewer.id,
        rejectionReason: reason,
      ),
    );
  }

  Future<bool> _submit(Future<void> Function() action) async {
    if (_reviewer.role != UserRole.admin || !_reviewer.isActive) {
      _errorMessage = 'You do not have permission to review access requests.';
      _notify();
      return false;
    }
    _isSubmitting = true;
    _errorMessage = null;
    _notify();
    try {
      await action();
      return !_isDisposed;
    } on AccessRequestFailure catch (failure) {
      if (!_isDisposed) _errorMessage = _messageFor(failure.type);
      return false;
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage = 'Unable to review this request right now.';
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  static String _messageFor(AccessRequestFailureType type) {
    return switch (type) {
      AccessRequestFailureType.alreadyReviewed =>
        'This request has already been reviewed.',
      AccessRequestFailureType.notFound =>
        'This request is no longer available.',
      AccessRequestFailureType.permissionDenied =>
        'You do not have permission to review access requests.',
      AccessRequestFailureType.unauthenticated =>
        'Your session has expired. Please sign in again.',
      AccessRequestFailureType.unavailable ||
      AccessRequestFailureType.timeout =>
        'Unable to complete this action. Check your connection and try again.',
      AccessRequestFailureType.invalidRole => 'Select a valid user role.',
      AccessRequestFailureType.noFacilitySelected =>
        'Select at least one facility.',
      AccessRequestFailureType.duplicateApprovedInvitation =>
        'An approved invitation already exists for this email.',
      AccessRequestFailureType.invalidData ||
      AccessRequestFailureType.missingIndex ||
      AccessRequestFailureType.unknown =>
        'Unable to review this request right now.',
    };
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
