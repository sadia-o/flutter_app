import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/dashboard/admin_dashboard_data.dart';
import '../../../domain/repositories/dashboard_repository.dart';
import '../../../domain/repositories/access_request_repository.dart';
import '../../../domain/models/access_request_failure.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/user_role.dart';
import 'user_dashboard_view_model.dart'; // To reuse DashboardLoadStatus

class AdminDashboardViewModel extends ChangeNotifier {
  final DashboardRepository dashboardRepository;
  final AppSessionController sessionController;
  final ActiveFacilityController activeFacilityController;
  final AccessRequestRepository? accessRequestRepository;

  DashboardLoadStatus _status = DashboardLoadStatus.initial;
  DashboardLoadStatus get status => _status;

  AdminDashboardData? _data;
  AdminDashboardData? get data => _data;

  AppUser get adminUser => sessionController.currentUser!;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _refreshErrorEventId = 0;
  int get refreshErrorEventId => _refreshErrorEventId;
  String? _refreshErrorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;

  // One-time facility-change error event (e.g. switching to a new facility fails)
  int _facilityErrorEventId = 0;
  int get facilityErrorEventId => _facilityErrorEventId;
  String? _facilityErrorMessage;
  String? get facilityErrorMessage => _facilityErrorMessage;

  bool _isLoading = false;
  bool _disposed = false;
  StreamSubscription<AdminDashboardData>? _streamSubscription;

  AdminDashboardViewModel({
    required this.dashboardRepository,
    required this.sessionController,
    required this.activeFacilityController,
    this.accessRequestRepository,
  });

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _status = DashboardLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await _fetchData(isRefresh: false);
  }

  Future<void> refresh() async {
    if (_isLoading) return;

    _isLoading = true;
    // Do not change _status to loading so existing data stays visible
    notifyListeners();

    await _fetchData(isRefresh: true);
  }

  void _subscribe(AppUser user, String? siteId) {
    _streamSubscription?.cancel();
    _streamSubscription = dashboardRepository
        .watchAdminDashboard(admin: user, siteId: siteId)
        .listen(
          (result) async {
            result = await _withRealPendingCounts(result);
            if (_disposed) return;
            _data = result;
            _status = DashboardLoadStatus.success;
            _errorMessage = null;
            if (result.selectedSite.id !=
                activeFacilityController.selectedSiteId) {
              activeFacilityController.selectSite(result.selectedSite.id);
            }
            notifyListeners();
          },
          onError: (e) {
            if (_disposed) return;
            if (_data == null) {
              _status = DashboardLoadStatus.failure;
              _errorMessage =
                  'Could not load dashboard data. Please try again.';
              notifyListeners();
            }
          },
        );
  }

  Future<void> refreshPendingCounts() async {
    if (_isLoading || _data == null || accessRequestRepository == null) return;
    _isLoading = true;
    try {
      _data = await _withRealPendingCounts(_data!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pendingRequestReviewed(DateTime? submittedAt) async {
    final current = _data;
    if (current == null) return;
    final localSubmittedAt = submittedAt?.toLocal();
    final now = DateTime.now();
    final reviewedToday =
        localSubmittedAt != null &&
        localSubmittedAt.year == now.year &&
        localSubmittedAt.month == now.month &&
        localSubmittedAt.day == now.day;
    _data = current.withPendingRequests(
      pendingRequestCount: current.pendingRequestCount > 0
          ? current.pendingRequestCount - 1
          : 0,
      newPendingRequestCountToday:
          reviewedToday && current.newPendingRequestCountToday > 0
          ? current.newPendingRequestCountToday - 1
          : current.newPendingRequestCountToday,
    );
    notifyListeners();
    await refreshPendingCounts();
  }

  /// Selects a new facility and reloads dashboard data.
  ///
  /// Selection rules:
  /// 1. Ignore same-site selection.
  /// 2. Validate the candidate site is permitted.
  /// 3. Preserve existing dashboard data.
  /// 4. Request dashboard data for the candidate site.
  /// 5. Only after repository success: update data AND commit to controller.
  /// 6. On failure: preserve previous data and site, expose one-time error.
  Future<void> selectFacility(String siteId) async {
    if (_isLoading) return;

    // Ignore same-site selection
    if (activeFacilityController.selectedSiteId == siteId) return;

    // Validate the candidate site
    if (!activeFacilityController.isPermitted(siteId)) {
      _facilityErrorMessage = 'You do not have access to that facility.';
      _facilityErrorEventId++;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final user = sessionController.currentUser;
      if (user == null || user.role != UserRole.admin) {
        throw Exception('Invalid session or role');
      }

      var result = await dashboardRepository.getAdminDashboard(
        admin: user,
        siteId: siteId,
      );
      result = _preservePendingCounts(result);

      // Only commit after success
      _data = result;
      _status = DashboardLoadStatus.success;
      _errorMessage = null;

      // Commit selected site to the shared controller AFTER success.
      activeFacilityController.selectSite(siteId);

      // Switch realtime subscription to new facility
      _subscribe(user, siteId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Admin dashboard facility change failed: $e');
      }
      // Preserve previous dashboard data and selected site
      _facilityErrorMessage = 'Failed to load facility. Please try again.';
      _facilityErrorEventId++;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchData({required bool isRefresh}) async {
    try {
      final user = sessionController.currentUser;
      if (user == null || user.role != UserRole.admin) {
        throw Exception('Invalid session or role');
      }
      if (user.siteAccessIds.isEmpty) {
        _streamSubscription?.cancel();
        _streamSubscription = null;
        _data = null;
        _status = DashboardLoadStatus.failure;
        _errorMessage = 'No facilities are assigned to your account.';
        return;
      }

      // Use the shared controller's current selected site.
      final siteId = activeFacilityController.selectedSiteId;

      var result = await dashboardRepository.getAdminDashboard(
        admin: user,
        siteId: siteId,
      );
      result = await _withRealPendingCounts(result);

      if (_disposed) return;
      _data = result;
      _status = DashboardLoadStatus.success;
      _errorMessage = null;

      if (result.selectedSite.id != activeFacilityController.selectedSiteId) {
        activeFacilityController.selectSite(result.selectedSite.id);
      }

      if (!isRefresh) {
        _subscribe(user, siteId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Admin dashboard load failed: $e');
      }
      if (isRefresh && _data != null) {
        _refreshErrorMessage = 'Failed to refresh dashboard. Please try again.';
        _refreshErrorEventId++;
      } else {
        _status = DashboardLoadStatus.failure;
        _errorMessage = 'Could not load dashboard data. Please try again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    super.dispose();
  }

  AdminDashboardData _preservePendingCounts(AdminDashboardData result) {
    final current = _data;
    if (accessRequestRepository == null || current == null) return result;
    return result.withPendingRequests(
      pendingRequestCount: current.pendingRequestCount,
      newPendingRequestCountToday: current.newPendingRequestCountToday,
    );
  }

  Future<AdminDashboardData> _withRealPendingCounts(
    AdminDashboardData result,
  ) async {
    final repository = accessRequestRepository;
    if (repository == null) return result;
    try {
      final pending = await repository.getPendingRequests();
      final now = DateTime.now();
      final newToday = pending.where((record) {
        final submittedAt = record.submittedAt?.toLocal();
        return submittedAt != null &&
            submittedAt.year == now.year &&
            submittedAt.month == now.month &&
            submittedAt.day == now.day;
      }).length;
      return result.withPendingRequests(
        pendingRequestCount: pending.length,
        newPendingRequestCountToday: newToday,
      );
    } on AccessRequestFailure catch (failure) {
      if (kDebugMode) {
        debugPrint(
          'Admin pending-request count load failed: ${failure.type.name}',
        );
      }
      _refreshErrorMessage = _pendingFailureMessage(failure.type);
      _refreshErrorEventId++;
      final current = _data;
      return result.withPendingRequests(
        pendingRequestCount: current?.pendingRequestCount ?? 0,
        newPendingRequestCountToday: current?.newPendingRequestCountToday ?? 0,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Admin pending-request count load failed: $error');
      }
      _refreshErrorMessage = 'Unable to load pending requests right now.';
      _refreshErrorEventId++;
      final current = _data;
      return result.withPendingRequests(
        pendingRequestCount: current?.pendingRequestCount ?? 0,
        newPendingRequestCountToday: current?.newPendingRequestCountToday ?? 0,
      );
    }
  }

  static String _pendingFailureMessage(AccessRequestFailureType type) {
    return switch (type) {
      AccessRequestFailureType.permissionDenied =>
        'You do not have permission to review access requests.',
      AccessRequestFailureType.unauthenticated =>
        'Your session has expired. Please sign in again.',
      AccessRequestFailureType.unavailable ||
      AccessRequestFailureType.timeout =>
        'Unable to load pending requests. Check your connection and try again.',
      AccessRequestFailureType.missingIndex =>
        'Pending requests are temporarily unavailable while database setup is completed.',
      AccessRequestFailureType.invalidData =>
        'One or more access requests could not be loaded.',
      AccessRequestFailureType.notFound ||
      AccessRequestFailureType.alreadyReviewed ||
      AccessRequestFailureType.invalidRole ||
      AccessRequestFailureType.noFacilitySelected ||
      AccessRequestFailureType.duplicateApprovedInvitation =>
        'Unable to load pending requests right now.',
      AccessRequestFailureType.unknown =>
        'Unable to load pending requests right now.',
    };
  }
}
