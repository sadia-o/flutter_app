import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../domain/models/dashboard/user_dashboard_data.dart';
import '../../../domain/repositories/dashboard_repository.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/user_role.dart';

enum DashboardLoadStatus { initial, loading, success, empty, failure }

class UserDashboardViewModel extends ChangeNotifier {
  final DashboardRepository dashboardRepository;
  final AppSessionController sessionController;
  final ActiveFacilityController? activeFacilityController;

  DashboardLoadStatus _status = DashboardLoadStatus.initial;
  DashboardLoadStatus get status => _status;

  UserDashboardData? _data;
  UserDashboardData? get data => _data;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _refreshErrorEventId = 0;
  int get refreshErrorEventId => _refreshErrorEventId;
  String? _refreshErrorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;

  bool _isLoading = false;
  bool _disposed = false;
  StreamSubscription<UserDashboardData>? _streamSubscription;

  UserDashboardViewModel({
    required this.dashboardRepository,
    required this.sessionController,
    this.activeFacilityController,
  }) {
    activeFacilityController?.addListener(_onFacilityChanged);
  }

  void _onFacilityChanged() {
    if (_disposed) return;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    load();
  }

  Future<void> load() async {
    if (_disposed || _isLoading) return;

    _isLoading = true;
    _status = DashboardLoadStatus.loading;
    _errorMessage = null;
    if (!_disposed) notifyListeners();

    await _fetchData(isRefresh: false);
  }

  Future<void> refresh() async {
    if (_disposed || _isLoading) return;

    _isLoading = true;
    // Do not change _status to loading so existing data stays visible
    if (!_disposed) notifyListeners();

    await _fetchData(isRefresh: true);
  }

  Future<void> _fetchData({required bool isRefresh}) async {
    try {
      final user = sessionController.currentUser;
      if (user == null ||
          (user.role != UserRole.viewer && user.role != UserRole.technician)) {
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

      final activeSiteId = activeFacilityController?.selectedSiteId;
      final siteId =
          activeSiteId ??
          (user.siteAccessIds.isNotEmpty ? user.siteAccessIds.first : null);

      if (!isRefresh) {
        final completer = Completer<void>();
        _streamSubscription?.cancel();
        _streamSubscription = dashboardRepository
            .watchUserDashboard(user: user, siteId: siteId)
            .listen(
              (newData) {
                if (_disposed) return;
                _data = newData;
                _status = DashboardLoadStatus.success;
                _errorMessage = null;
                if (!completer.isCompleted) completer.complete();
                notifyListeners();
              },
              onError: (error) {
                if (_disposed) return;
                if (_data == null) {
                  _status = DashboardLoadStatus.failure;
                  _errorMessage =
                      'Could not load dashboard data. Please try again.';
                }
                if (!completer.isCompleted) completer.complete();
                notifyListeners();
              },
            );
        await completer.future;
      } else {
        final result = await dashboardRepository.getUserDashboard(
          user: user,
          siteId: siteId,
        );
        if (_disposed) return;
        _data = result;
        _status = DashboardLoadStatus.success;
        _errorMessage = null;
      }
    } catch (e) {
      if (_disposed) return;
      if (kDebugMode) {
        debugPrint('User dashboard load failed: $e');
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
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    activeFacilityController?.removeListener(_onFacilityChanged);
    super.dispose();
  }
}
