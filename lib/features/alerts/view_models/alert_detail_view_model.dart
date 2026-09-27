import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/alert.dart';
import '../../../domain/models/detection_event.dart';
import '../../../domain/models/station.dart';
import '../../../domain/repositories/alert_repository.dart';
import '../../../domain/repositories/station_repository.dart';
import '../models/alert_permissions.dart';

class AlertDetailViewModel extends ChangeNotifier {
  final String alertId;
  final AlertRepository _alertRepository;
  final StationRepository _stationRepository;
  final AppSessionController _sessionController;
  final ActiveFacilityController _activeFacilityController;

  AlertDetailViewModel({
    required this.alertId,
    required AlertRepository alertRepository,
    required StationRepository stationRepository,
    required AppSessionController sessionController,
    required ActiveFacilityController activeFacilityController,
  }) : _alertRepository = alertRepository,
       _stationRepository = stationRepository,
       _sessionController = sessionController,
       _activeFacilityController = activeFacilityController {
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

  Alert? _alert;
  Alert? get alert => _alert;

  Alert? _lastUpdatedAlert;
  Alert? get lastUpdatedAlert => _lastUpdatedAlert;

  Station? _station;
  Station? get station => _station;

  AlertPermissions? _permissions;
  AlertPermissions? get permissions => _permissions;

  DetectionEvent? _linkedEvidenceEvent;
  DetectionEvent? get linkedEvidenceEvent => _linkedEvidenceEvent;

  bool get hasEvidence => _linkedEvidenceEvent != null;

  bool _isMutating = false;
  bool get isMutating => _isMutating;

  StreamSubscription<Alert?>? _alertSub;
  bool _disposed = false;

  Future<void> _initialize() async {
    final role = _sessionController.currentUser?.role;
    if (role != null) {
      _permissions = AlertPermissions.fromRole(
        role,
        supportsMutations: _alertRepository.supportsMutations,
      );
    }
    _alertSub?.cancel();
    _alertSub = _alertRepository.watchAlertById(alertId).listen((updated) {
      if (_disposed) return;
      if (updated != null) {
        _alert = updated;
        notifyListeners();
      }
    });
    await _loadData();
    if (_alert != null && !_alert!.isRead) {
      await _markRead();
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final a = await _alertRepository.getAlertById(alertId);
      final s = await _stationRepository.getStationById(a.stationId);

      // Verify unauthorized site alert access
      if (s?.siteId != _activeFacilityController.selectedSiteId) {
        throw StateError('Unauthorized site access');
      }

      _alert = a;
      _station = s;

      _linkedEvidenceEvent = null;
      if (s!.hasCamera) {
        final events = await _stationRepository.getStationEvents(s.id);
        try {
          _linkedEvidenceEvent = events.firstWhere(
            (e) =>
                e.stationId == a.stationId &&
                (e.id == a.detectionEventId || e.alertId == a.id),
          );
        } catch (_) {}
      }
    } catch (e) {
      _error = 'Failed to load alert details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      final a = await _alertRepository.getAlertById(alertId);
      final s = await _stationRepository.getStationById(a.stationId);

      if (s?.siteId != _activeFacilityController.selectedSiteId) {
        throw StateError('Unauthorized site access');
      }

      _alert = a;
      _station = s;

      _linkedEvidenceEvent = null;
      if (s!.hasCamera) {
        final events = await _stationRepository.getStationEvents(s.id);
        try {
          _linkedEvidenceEvent = events.firstWhere(
            (e) =>
                e.stationId == a.stationId &&
                (e.id == a.detectionEventId || e.alertId == a.id),
          );
        } catch (_) {}
      }
    } catch (e) {
      _refreshErrorMessage = 'Failed to refresh alert.';
      _refreshErrorEventId++;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _markRead() async {
    try {
      final updated = await _alertRepository.markAlertRead(alertId: alertId);
      _alert = updated;
      _lastUpdatedAlert = updated;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> resolveAlert() async {
    if (!_alertRepository.supportsMutations) {
      _actionErrorMessage = 'Alert mutations are unavailable in this pilot.';
      _actionErrorEventId++;
      notifyListeners();
      return;
    }
    if (_permissions?.canResolve != true) return;
    if (_isMutating) return;
    final user = _sessionController.currentUser;
    if (user == null) return;

    _isMutating = true;
    notifyListeners();

    try {
      final updated = await _alertRepository.resolveAlert(
        alertId: alertId,
        resolvedByUserId: user.id,
      );
      _alert = updated;
      _lastUpdatedAlert = updated;
      _actionSuccessMessage = 'Alert resolved successfully.';
      _actionSuccessEventId++;
    } catch (e) {
      _actionErrorMessage = 'Failed to resolve alert.';
      _actionErrorEventId++;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> snoozeAlert(DateTime until) async {
    if (!_alertRepository.supportsMutations) {
      _actionErrorMessage = 'Alert mutations are unavailable in this pilot.';
      _actionErrorEventId++;
      notifyListeners();
      return;
    }
    if (_permissions?.canSnooze != true) return;
    if (_isMutating) return;

    _isMutating = true;
    notifyListeners();

    try {
      final updated = await _alertRepository.snoozeAlert(
        alertId: alertId,
        until: until,
      );
      _alert = updated;
      _lastUpdatedAlert = updated;
      _actionSuccessMessage = 'Alert snoozed for 1 hour.';
      _actionSuccessEventId++;
    } catch (e) {
      _actionErrorMessage = 'Failed to snooze alert.';
      _actionErrorEventId++;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> assignAlert(String technicianId) async {
    if (!_alertRepository.supportsMutations) {
      _actionErrorMessage = 'Alert mutations are unavailable in this pilot.';
      _actionErrorEventId++;
      notifyListeners();
      return;
    }
    if (_permissions?.canAssign != true) return;
    if (_isMutating) return;

    _isMutating = true;
    notifyListeners();

    try {
      final updated = await _alertRepository.assignAlert(
        alertId: alertId,
        technicianId: technicianId,
      );
      _alert = updated;
      _lastUpdatedAlert = updated;
      _actionSuccessMessage = 'Alert assigned to technician.';
      _actionSuccessEventId++;
    } catch (e) {
      _actionErrorMessage = 'Failed to assign technician.';
      _actionErrorEventId++;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> dismissAlert() async {
    if (!_alertRepository.supportsMutations) {
      _actionErrorMessage = 'Alert mutations are unavailable in this pilot.';
      _actionErrorEventId++;
      notifyListeners();
      return;
    }
    if (_permissions?.canDismiss != true) return;
    if (_isMutating) return;
    final user = _sessionController.currentUser;
    if (user == null) return;

    _isMutating = true;
    notifyListeners();

    try {
      final updated = await _alertRepository.dismissAlert(
        alertId: alertId,
        dismissedByUserId: user.id,
      );
      _alert = updated;
      _lastUpdatedAlert = updated;
      _actionSuccessMessage = 'Alert dismissed.';
      _actionSuccessEventId++;
    } catch (e) {
      _actionErrorMessage = 'Failed to dismiss alert.';
      _actionErrorEventId++;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _alertSub?.cancel();
    _alertSub = null;
    super.dispose();
  }
}
