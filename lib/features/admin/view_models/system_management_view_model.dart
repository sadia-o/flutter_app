import 'package:flutter/foundation.dart';

import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/settings_facility_option.dart';
import '../../../domain/models/user_profile_failure.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/user_repository.dart';

enum SystemManagementStatus { initial, loading, success, failure, denied }

class SystemManagementViewModel extends ChangeNotifier {
  SystemManagementViewModel({
    required UserRepository userRepository,
    required SettingsRepository settingsRepository,
    required AppSessionController sessionController,
  }) : _userRepository = userRepository,
       _settingsRepository = settingsRepository,
       _sessionController = sessionController;

  final UserRepository _userRepository;
  final SettingsRepository _settingsRepository;
  final AppSessionController _sessionController;

  SystemManagementStatus _status = SystemManagementStatus.initial;
  List<AppUser> _users = const [];
  List<SettingsFacilityOption> _sites = const [];
  String? _errorMessage;
  String? _refreshErrorMessage;
  int _refreshErrorEventId = 0;
  bool _isLoading = false;
  bool _disposed = false;
  bool _hasLoaded = false;

  SystemManagementStatus get status => _status;
  List<AppUser> get users => _users;
  List<SettingsFacilityOption> get sites => _sites;
  String? get errorMessage => _errorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;
  int get refreshErrorEventId => _refreshErrorEventId;
  bool get isRefreshing => _isLoading && _hasLoaded;
  int get totalUsers => _users.length;
  int get adminCount => _countRole(UserRole.admin);
  int get technicianCount => _countRole(UserRole.technician);
  int get viewerCount => _countRole(UserRole.viewer);
  int get activeCount => _users.where((user) => user.isActive).length;
  int get disabledCount => totalUsers - activeCount;
  bool get isAuthorized {
    final user = _sessionController.currentUser;
    return user != null && user.role == UserRole.admin && user.isActive;
  }

  String get userSummary =>
      '${_plural(totalUsers, 'user')} · '
      '${_plural(adminCount, 'admin')} · '
      '${_plural(technicianCount, 'technician')} · '
      '${_plural(viewerCount, 'viewer')}';

  Future<void> load() => _fetch(refresh: false);
  Future<void> refresh() => _fetch(refresh: true);

  Future<void> _fetch({required bool refresh}) async {
    if (_isLoading || _disposed) return;
    if (!isAuthorized) {
      _status = SystemManagementStatus.denied;
      _errorMessage = 'You do not have permission to access System Management.';
      _notify();
      return;
    }
    _isLoading = true;
    if (!_hasLoaded) _status = SystemManagementStatus.loading;
    _notify();
    try {
      final admin = _sessionController.currentUser!;
      final sites = await _settingsRepository.getPermittedFacilities(
        admin.siteAccessIds,
      );
      if (_disposed) return;
      _sites = List.unmodifiable(sites);
      final result = await _userRepository.getUsers();
      if (_disposed) return;
      final users = result.toList()
        ..sort(
          (left, right) => _displayName(
            left,
          ).toLowerCase().compareTo(_displayName(right).toLowerCase()),
        );
      _users = List.unmodifiable(users);
      _status = SystemManagementStatus.success;
      _errorMessage = null;
      _refreshErrorMessage = null;
      _hasLoaded = true;
    } on UserProfileFailure catch (failure) {
      if (_disposed) return;
      final message = failure.type == UserProfileFailureType.permissionDenied
          ? 'You do not have permission to view user management.'
          : 'Users could not be loaded. Pull to refresh or try again.';
      if (refresh && _hasLoaded) {
        _refreshErrorMessage = message;
        _refreshErrorEventId++;
      } else {
        _errorMessage = message;
        _status = SystemManagementStatus.failure;
      }
    } catch (_) {
      if (_disposed) return;
      const message =
          'Users could not be loaded. Pull to refresh or try again.';
      if (refresh && _hasLoaded) {
        _refreshErrorMessage = message;
        _refreshErrorEventId++;
      } else {
        _errorMessage = message;
        _status = SystemManagementStatus.failure;
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  int _countRole(UserRole role) =>
      _users.where((user) => user.role == role).length;

  static String displayName(AppUser user) => _displayName(user);
  static String initials(AppUser user) {
    final name = _displayName(user);
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _displayName(AppUser user) {
    final name = user.name.trim();
    if (name.isNotEmpty) return name;
    final emailName = user.email.trim().split('@').first;
    return emailName.isEmpty ? 'Unknown user' : emailName;
  }

  static String _plural(int value, String label) =>
      '$value $label${value == 1 ? '' : 's'}';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
