import 'package:flutter/foundation.dart';

import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/user_profile_failure.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/user_repository.dart';

enum UserManagementStatus { initial, loading, success, failure, denied }

enum UserRoleFilter { all, admin, technician, viewer }

enum UserStatusFilter { all, active, disabled }

class UserManagementViewModel extends ChangeNotifier {
  UserManagementViewModel({
    required UserRepository userRepository,
    required AppSessionController sessionController,
  }) : _userRepository = userRepository,
       _sessionController = sessionController;

  final UserRepository _userRepository;
  final AppSessionController _sessionController;

  UserManagementStatus _status = UserManagementStatus.initial;
  List<AppUser> _users = const [];
  String _query = '';
  UserRoleFilter _roleFilter = UserRoleFilter.all;
  UserStatusFilter _statusFilter = UserStatusFilter.all;
  String? _errorMessage;
  String? _refreshErrorMessage;
  int _refreshErrorEventId = 0;
  bool _loading = false;
  bool _loaded = false;
  bool _disposed = false;

  UserManagementStatus get status => _status;
  List<AppUser> get users => _users;
  String get query => _query;
  UserRoleFilter get roleFilter => _roleFilter;
  UserStatusFilter get statusFilter => _statusFilter;
  String? get errorMessage => _errorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;
  int get refreshErrorEventId => _refreshErrorEventId;
  bool get isRefreshing => _loading && _loaded;
  bool get hasFilters =>
      _query.isNotEmpty ||
      _roleFilter != UserRoleFilter.all ||
      _statusFilter != UserStatusFilter.all;

  int get totalCount => _users.length;
  int get activeCount => _users.where((user) => user.isActive).length;
  int get disabledCount => totalCount - activeCount;
  int get adminCount => _roleCount(UserRole.admin);
  int get technicianCount => _roleCount(UserRole.technician);
  int get viewerCount => _roleCount(UserRole.viewer);

  List<AppUser> get filteredUsers {
    final normalizedQuery = _query.toLowerCase();
    return List.unmodifiable(
      _users.where((user) {
        final matchesQuery =
            normalizedQuery.isEmpty ||
            <String>[
              displayName(user),
              user.firstName ?? '',
              user.lastName ?? '',
              user.email,
            ].any((value) => value.toLowerCase().contains(normalizedQuery));
        final matchesRole = switch (_roleFilter) {
          UserRoleFilter.all => true,
          UserRoleFilter.admin => user.role == UserRole.admin,
          UserRoleFilter.technician => user.role == UserRole.technician,
          UserRoleFilter.viewer => user.role == UserRole.viewer,
        };
        final matchesStatus = switch (_statusFilter) {
          UserStatusFilter.all => true,
          UserStatusFilter.active => user.isActive,
          UserStatusFilter.disabled => !user.isActive,
        };
        return matchesQuery && matchesRole && matchesStatus;
      }),
    );
  }

  bool get isAuthorized {
    final user = _sessionController.currentUser;
    return user != null && user.role == UserRole.admin && user.isActive;
  }

  Future<void> load() => _fetch(refresh: false);
  Future<void> refresh() => _fetch(refresh: true);

  Future<void> _fetch({required bool refresh}) async {
    if (_loading || _disposed) return;
    if (!isAuthorized) {
      _status = UserManagementStatus.denied;
      _errorMessage = 'You do not have permission to manage users.';
      _notify();
      return;
    }
    _loading = true;
    if (!_loaded) _status = UserManagementStatus.loading;
    _notify();
    try {
      final result = await _userRepository.getUsers();
      if (_disposed) return;
      final sorted = result.toList()..sort(compareUsers);
      _users = List.unmodifiable(sorted);
      _status = UserManagementStatus.success;
      _errorMessage = null;
      _refreshErrorMessage = null;
      _loaded = true;
    } on UserProfileFailure catch (failure) {
      if (_disposed) return;
      final message = failure.type == UserProfileFailureType.permissionDenied
          ? 'You do not have permission to view users.'
          : 'Users could not be loaded. Check your connection and try again.';
      _handleFailure(message, refresh: refresh);
    } catch (_) {
      if (_disposed) return;
      _handleFailure(
        'Users could not be loaded. Check your connection and try again.',
        refresh: refresh,
      );
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void updateQuery(String value) {
    final normalized = value.trim().toLowerCase();
    if (_query == normalized) return;
    _query = normalized;
    _notify();
  }

  void selectRole(UserRoleFilter value) {
    if (_roleFilter == value) return;
    _roleFilter = value;
    _notify();
  }

  void selectStatus(UserStatusFilter value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    _notify();
  }

  void resetFilters() {
    _query = '';
    _roleFilter = UserRoleFilter.all;
    _statusFilter = UserStatusFilter.all;
    _notify();
  }

  void _handleFailure(String message, {required bool refresh}) {
    if (refresh && _loaded) {
      _refreshErrorMessage = message;
      _refreshErrorEventId++;
    } else {
      _errorMessage = message;
      _status = UserManagementStatus.failure;
    }
  }

  int _roleCount(UserRole role) =>
      _users.where((user) => user.role == role).length;

  static int compareUsers(AppUser left, AppUser right) {
    if (left.isActive != right.isActive) return left.isActive ? -1 : 1;
    final name = displayName(
      left,
    ).toLowerCase().compareTo(displayName(right).toLowerCase());
    if (name != 0) return name;
    final email = left.email.toLowerCase().compareTo(right.email.toLowerCase());
    return email != 0 ? email : left.id.compareTo(right.id);
  }

  static String displayName(AppUser user) {
    if (user.name.trim().isNotEmpty) return user.name.trim();
    final combined = [
      user.firstName?.trim() ?? '',
      user.lastName?.trim() ?? '',
    ].where((part) => part.isNotEmpty).join(' ');
    if (combined.isNotEmpty) return combined;
    final prefix = user.email.trim().split('@').first;
    return prefix.isEmpty ? 'Unknown User' : prefix;
  }

  static String initials(AppUser user) {
    final parts = displayName(
      user,
    ).split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return String.fromCharCodes(parts.first.runes.take(2)).toUpperCase();
    }
    return '${String.fromCharCode(parts.first.runes.first)}'
            '${String.fromCharCode(parts.last.runes.first)}'
        .toUpperCase();
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
