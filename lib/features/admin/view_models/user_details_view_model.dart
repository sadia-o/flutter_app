import 'package:flutter/foundation.dart';

import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/settings_facility_option.dart';
import '../../../domain/models/user_profile_failure.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/user_repository.dart';

enum UserDetailsStatus { initial, loading, success, missing, failure, denied }

class UserDetailsViewModel extends ChangeNotifier {
  UserDetailsViewModel({
    required this.userId,
    required UserRepository userRepository,
    required SettingsRepository settingsRepository,
    required AppSessionController sessionController,
  }) : _userRepository = userRepository,
       _settingsRepository = settingsRepository,
       _sessionController = sessionController;

  final String userId;
  final UserRepository _userRepository;
  final SettingsRepository _settingsRepository;
  final AppSessionController _sessionController;

  UserDetailsStatus _status = UserDetailsStatus.initial;
  AppUser? _user;
  List<SettingsFacilityOption> _facilities = const [];
  String? _errorMessage;
  bool _loading = false;
  bool _disposed = false;

  UserDetailsStatus get status => _status;
  AppUser? get user => _user;
  List<SettingsFacilityOption> get facilities => _facilities;
  String? get errorMessage => _errorMessage;
  bool get canManageTarget {
    final current = _sessionController.currentUser;
    final target = _user;
    return current != null &&
        current.role == UserRole.admin &&
        current.isActive &&
        target != null &&
        target.id != current.id &&
        target.role != UserRole.admin;
  }

  bool get isAuthorized {
    final current = _sessionController.currentUser;
    return current != null &&
        current.role == UserRole.admin &&
        current.isActive;
  }

  Future<void> load() async {
    if (_loading || _disposed) return;
    if (!isAuthorized) {
      _status = UserDetailsStatus.denied;
      _errorMessage = 'You do not have permission to manage users.';
      _notify();
      return;
    }
    _loading = true;
    _status = UserDetailsStatus.loading;
    _notify();
    try {
      final loaded = await _userRepository.getUserById(userId);
      if (_disposed) return;
      if (loaded == null) {
        _status = UserDetailsStatus.missing;
        _errorMessage = 'This user profile is no longer available.';
        return;
      }
      final options = await _settingsRepository.getPermittedFacilities(
        loaded.siteAccessIds,
      );
      if (_disposed) return;
      final byId = {for (final option in options) option.id: option};
      _facilities = List.unmodifiable([
        for (final id in loaded.siteAccessIds)
          byId[id] ??
              SettingsFacilityOption(
                id: id,
                name: 'Unknown facility',
                stationCount: 0,
                offlineStationCount: 0,
              ),
      ]);
      _user = loaded;
      _status = UserDetailsStatus.success;
      _errorMessage = null;
    } on UserProfileFailure catch (failure) {
      if (_disposed) return;
      _status = UserDetailsStatus.failure;
      _errorMessage = failure.type == UserProfileFailureType.permissionDenied
          ? 'You do not have permission to view users.'
          : 'Users could not be loaded. Check your connection and try again.';
    } catch (_) {
      if (_disposed) return;
      _status = UserDetailsStatus.failure;
      _errorMessage =
          'Users could not be loaded. Check your connection and try again.';
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
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
