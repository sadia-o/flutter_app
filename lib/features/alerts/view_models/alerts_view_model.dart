import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/alert.dart';
import '../../../domain/models/alert_type.dart';
import '../../../domain/models/alert_status.dart';
import '../../../domain/models/alert_severity.dart';
import '../../../domain/models/station.dart';
import '../../../domain/repositories/alert_repository.dart';
import '../../../domain/repositories/station_repository.dart';
import '../../navigation/models/admin_alert_list_preset.dart';
import '../models/alert_list_filter.dart';
import '../models/alert_permissions.dart';
import '../models/alert_activity_point.dart';
import '../models/alert_hotspot_station.dart';

class AlertsViewModel extends ChangeNotifier {
  final AlertRepository _alertRepository;
  final StationRepository _stationRepository;
  final AppSessionController _sessionController;
  final ActiveFacilityController _activeFacilityController;

  AlertsViewModel({
    required AlertRepository alertRepository,
    required StationRepository stationRepository,
    required AppSessionController sessionController,
    required ActiveFacilityController activeFacilityController,
  }) : _alertRepository = alertRepository,
       _stationRepository = stationRepository,
       _sessionController = sessionController,
       _activeFacilityController = activeFacilityController {
    _activeFacilityController.addListener(_onFacilityChanged);
    _initialize();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _refreshErrorEventId = 0;
  int get refreshErrorEventId => _refreshErrorEventId;
  String? _refreshErrorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;

  int _actionSuccessEventId = 0;
  int get actionSuccessEventId => _actionSuccessEventId;
  String? _actionSuccessMessage;
  String? get actionSuccessMessage => _actionSuccessMessage;

  int _actionErrorEventId = 0;
  int get actionErrorEventId => _actionErrorEventId;
  String? _actionErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  List<Alert> _allAlerts = [];
  List<Station> _allStations = [];

  AlertListFilter _selectedFilter = AlertListFilter.all;
  AlertListFilter get selectedFilter => _selectedFilter;

  AlertPermissions? _permissions;
  AlertPermissions? get permissions => _permissions;

  final Set<String> _mutatingAlertIds = {};

  bool isMutating(String alertId) => _mutatingAlertIds.contains(alertId);

  String? _lastLoadedSiteId;

  StreamSubscription<List<Alert>>? _alertsSub;
  StreamSubscription<List<Station>>? _stationsSub;

  @override
  void dispose() {
    _alertsSub?.cancel();
    _stationsSub?.cancel();
    _alertsSub = null;
    _stationsSub = null;
    _activeFacilityController.removeListener(_onFacilityChanged);
    super.dispose();
  }

  void _onFacilityChanged() {
    final currentSite = _activeFacilityController.selectedSiteId;
    if (currentSite != null && currentSite != _lastLoadedSiteId) {
      _alertsSub?.cancel();
      _stationsSub?.cancel();
      _alertsSub = null;
      _stationsSub = null;
      _loadData();
    }
  }

  Future<void> _initialize() async {
    final role = _sessionController.currentUser?.role;
    if (role != null) {
      _permissions = AlertPermissions.fromRole(
        role,
        supportsMutations: _alertRepository.supportsMutations,
      );
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    final siteId = _activeFacilityController.selectedSiteId;
    if (siteId == null) {
      _error = 'No facility selected.';
      notifyListeners();
      return;
    }

    if (_sessionController.currentUser == null) {
      _error = 'Not authenticated.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alertsSub?.cancel();
      _stationsSub?.cancel();

      _allStations = await _stationRepository.getStations(siteId: siteId);
      _allAlerts = await _alertRepository.getAlerts(siteId: siteId);
      _lastLoadedSiteId = siteId;

      _alertsSub = _alertRepository.watchAlerts(siteId: siteId).listen((
        alerts,
      ) {
        _allAlerts = alerts;
        notifyListeners();
      });

      _stationsSub = _stationRepository.watchStations(siteId: siteId).listen((
        stations,
      ) {
        _allStations = stations;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load alerts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final siteId = _activeFacilityController.selectedSiteId;
    if (siteId == null) return;

    try {
      final newStations = await _stationRepository.getStations(siteId: siteId);
      final newAlerts = await _alertRepository.getAlerts(siteId: siteId);
      _allStations = newStations;
      _allAlerts = newAlerts;
      _lastLoadedSiteId = siteId;
    } catch (e) {
      _refreshErrorMessage = 'Failed to refresh alerts: $e';
      _refreshErrorEventId++;
    } finally {
      notifyListeners();
    }
  }

  void applyPreset(AdminAlertListPreset preset) {
    if (preset == AdminAlertListPreset.all) {
      setFilter(AlertListFilter.all);
    } else if (preset == AdminAlertListPreset.criticalUnresolved) {
      // Figma design does not show a "critical" filter chip, but we can set it to All
      // Or maybe there is a way to filter, for now we set to all, since critical banner handles it.
      setFilter(AlertListFilter.all);
    }
  }

  void setFilter(AlertListFilter filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  List<Alert> get _filteredAlerts {
    switch (_selectedFilter) {
      case AlertListFilter.all:
        return _allAlerts;
      case AlertListFilter.rodent:
        return _allAlerts.where((a) => a.type == AlertType.rodent).toList();
      case AlertListFilter.lowBait:
        return _allAlerts.where((a) => a.type == AlertType.lowBait).toList();
      case AlertListFilter.tamper:
        return _allAlerts.where((a) => a.type == AlertType.tamper).toList();
      case AlertListFilter.offline:
        return _allAlerts
            .where((a) => a.type == AlertType.stationOffline)
            .toList();
    }
  }

  List<Alert> get todayAlerts {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _filteredAlerts
        .where((a) => !a.timestamp.isBefore(todayStart))
        .toList();
  }

  List<Alert> get earlierAlerts {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _filteredAlerts
        .where((a) => a.timestamp.isBefore(todayStart))
        .toList();
  }

  int get unreadCount => _allAlerts.where((a) => !a.isRead).length;

  int get unresolvedCount => _allAlerts
      .where(
        (a) =>
            a.status != AlertStatus.resolved &&
            a.status != AlertStatus.dismissed,
      )
      .length;

  int get highCount =>
      _allAlerts.where((a) => a.severity == AlertSeverity.critical).length;
  int get mediumCount =>
      _allAlerts.where((a) => a.severity == AlertSeverity.warning).length;
  int get lowCount =>
      _allAlerts.where((a) => a.severity == AlertSeverity.info).length;

  List<Alert> get criticalUnresolvedAlerts {
    return _allAlerts.where((a) {
      final isCritical = a.severity == AlertSeverity.critical;
      final isUnresolved =
          a.status != AlertStatus.resolved && a.status != AlertStatus.dismissed;
      return isCritical && isUnresolved;
    }).toList();
  }

  Station? getStationForAlert(String alertId) {
    final alert = _allAlerts.cast<Alert?>().firstWhere(
      (a) => a?.id == alertId,
      orElse: () => null,
    );
    if (alert == null) return null;
    return _allStations.cast<Station?>().firstWhere(
      (s) => s?.id == alert.stationId,
      orElse: () => null,
    );
  }

  List<AlertActivityPoint> get sevenDayActivity {
    final map = <DateTime, int>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 6; i >= 0; i--) {
      map[today.subtract(Duration(days: i))] = 0;
    }

    for (final alert in _allAlerts) {
      final d = DateTime(
        alert.timestamp.year,
        alert.timestamp.month,
        alert.timestamp.day,
      );
      if (map.containsKey(d)) {
        map[d] = map[d]! + 1;
      }
    }

    return map.entries
        .map((e) => AlertActivityPoint(day: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
  }

  List<AlertHotspotStation> get hotspotStations {
    final stationCounts = <String, int>{};
    for (final alert in _allAlerts) {
      stationCounts[alert.stationId] =
          (stationCounts[alert.stationId] ?? 0) + 1;
    }

    final hotspots = stationCounts.entries.map((e) {
      final st = _allStations.cast<Station?>().firstWhere(
        (s) => s?.id == e.key,
        orElse: () => null,
      );
      return AlertHotspotStation(
        stationId: e.key,
        location: st?.locationDescription ?? 'Unknown',
        alertCount: e.value,
      );
    }).toList();

    hotspots.sort((a, b) {
      final cmp = b.alertCount.compareTo(a.alertCount);
      if (cmp != 0) return cmp;
      return a.stationId.compareTo(b.stationId);
    });

    return hotspots.take(4).toList();
  }

  Future<void> resolveAlert(String alertId) async {
    if (_permissions?.canResolve != true) return;
    if (_mutatingAlertIds.contains(alertId)) return;
    final user = _sessionController.currentUser;
    if (user == null) return;

    _mutatingAlertIds.add(alertId);
    notifyListeners();

    try {
      final updatedAlert = await _alertRepository.resolveAlert(
        alertId: alertId,
        resolvedByUserId: user.id,
      );
      _updateLocalAlert(updatedAlert);
      _actionSuccessMessage = 'Alert resolved successfully.';
      _actionSuccessEventId++;
    } catch (e) {
      _actionErrorMessage = 'Failed to resolve alert: $e';
      _actionErrorEventId++;
    } finally {
      _mutatingAlertIds.remove(alertId);
      notifyListeners();
    }
  }

  Future<void> snoozeAlert(String alertId, DateTime until) async {
    if (_permissions?.canSnooze != true) return;
    if (_mutatingAlertIds.contains(alertId)) return;

    _mutatingAlertIds.add(alertId);
    notifyListeners();

    try {
      final updatedAlert = await _alertRepository.snoozeAlert(
        alertId: alertId,
        until: until,
      );
      _updateLocalAlert(updatedAlert);
      _actionSuccessMessage = 'Alert snoozed for 1 hour.';
      _actionSuccessEventId++;
    } catch (e) {
      _actionErrorMessage = 'Failed to snooze alert: $e';
      _actionErrorEventId++;
    } finally {
      _mutatingAlertIds.remove(alertId);
      notifyListeners();
    }
  }

  Future<void> assignAlert(String alertId, String technicianId) async {
    if (_permissions?.canAssign != true) return;
    if (_mutatingAlertIds.contains(alertId)) return;

    _mutatingAlertIds.add(alertId);
    notifyListeners();

    try {
      final updatedAlert = await _alertRepository.assignAlert(
        alertId: alertId,
        technicianId: technicianId,
      );
      _updateLocalAlert(updatedAlert);
      _actionSuccessMessage = 'Alert assigned to technician.';
      _actionSuccessEventId++;
    } catch (e) {
      _actionErrorMessage = 'Failed to assign technician: $e';
      _actionErrorEventId++;
    } finally {
      _mutatingAlertIds.remove(alertId);
      notifyListeners();
    }
  }

  Future<void> dismissAlert(String alertId) async {
    if (_permissions?.canDismiss != true) return;
    if (_mutatingAlertIds.contains(alertId)) return;
    final user = _sessionController.currentUser;
    if (user == null) return;

    _mutatingAlertIds.add(alertId);
    notifyListeners();

    try {
      final updatedAlert = await _alertRepository.dismissAlert(
        alertId: alertId,
        dismissedByUserId: user.id,
      );
      _updateLocalAlert(updatedAlert);
      _actionSuccessMessage = 'Alert dismissed.';
      _actionSuccessEventId++;
    } catch (e) {
      _actionErrorMessage = 'Failed to dismiss alert: $e';
      _actionErrorEventId++;
    } finally {
      _mutatingAlertIds.remove(alertId);
      notifyListeners();
    }
  }

  Future<void> markAlertRead(String alertId) async {
    final idx = _allAlerts.indexWhere((a) => a.id == alertId);
    if (idx != -1 && !_allAlerts[idx].isRead) {
      try {
        final updated = await _alertRepository.markAlertRead(alertId: alertId);
        _updateLocalAlert(updated);
        notifyListeners();
      } catch (_) {}
    }
  }

  void _updateLocalAlert(Alert updated) {
    final idx = _allAlerts.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      final list = _allAlerts.toList();
      list[idx] = updated;
      _allAlerts = list;
    }
  }

  void applyUpdatedAlert(Alert updatedAlert) {
    final idx = _allAlerts.indexWhere((a) => a.id == updatedAlert.id);
    if (idx != -1) {
      final list = _allAlerts.toList();
      list[idx] = updatedAlert;
      _allAlerts = list;
      notifyListeners();
    }
  }
}
