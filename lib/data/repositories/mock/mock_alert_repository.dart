import '../../../domain/models/alert.dart';
import '../../../domain/models/alert_status.dart';
import '../../../domain/repositories/alert_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockAlertRepository implements AlertRepository {
  final MockBaitGuardDataSource _dataSource;

  MockAlertRepository(this._dataSource);

  @override
  Future<List<Alert>> getAlerts({required String siteId}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Find all stations for the site
    final siteStationIds = _dataSource.stations
        .where((s) => s.siteId == siteId)
        .map((s) => s.id)
        .toSet();

    // Return alerts for those stations
    return _dataSource.alerts
        .where((a) => siteStationIds.contains(a.stationId))
        .toList();
  }

  @override
  Future<Alert> getAlertById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _dataSource.alerts.firstWhere((a) => a.id == id);
    } catch (_) {
      throw StateError('Alert not found');
    }
  }

  @override
  Future<Alert> markAlertRead({required String alertId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final alert = await getAlertById(alertId);
    if (alert.isRead) return alert;
    return _dataSource.updateAlert(alert.copyWith(isRead: true));
  }

  @override
  Future<Alert> resolveAlert({
    required String alertId,
    required String resolvedByUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final alert = await getAlertById(alertId);
    return _dataSource.updateAlert(
      alert.copyWith(
        status: AlertStatus.resolved,
        resolvedAt: DateTime.now(),
        resolvedByUserId: resolvedByUserId,
      ),
    );
  }

  @override
  Future<Alert> snoozeAlert({
    required String alertId,
    required DateTime until,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final alert = await getAlertById(alertId);
    return _dataSource.updateAlert(alert.copyWith(snoozedUntil: until));
  }

  @override
  Future<Alert> assignAlert({
    required String alertId,
    required String technicianId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final alert = await getAlertById(alertId);
    final techName = technicianId == 'tech_1'
        ? 'Ahmed Khan'
        : (technicianId == 'tech_2' ? 'Sarah Jenkins' : 'Technician');
    return _dataSource.updateAlert(
      alert.copyWith(
        assignedTechnicianId: techName,
        status: AlertStatus.inReview,
      ),
    );
  }

  @override
  Future<Alert> dismissAlert({
    required String alertId,
    required String dismissedByUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final alert = await getAlertById(alertId);
    return _dataSource.updateAlert(
      alert.copyWith(
        status: AlertStatus.dismissed,
        dismissedAt: DateTime.now(),
        dismissedByUserId: dismissedByUserId,
      ),
    );
  }

  @override
  bool get supportsMutations => true;

  @override
  Stream<List<Alert>> watchAlerts({required String siteId}) async* {
    final alerts = _dataSource.alerts.where((a) {
      final station = _dataSource.stations.firstWhere(
        (s) => s.id == a.stationId,
        orElse: () => _dataSource.stations.first,
      );
      return station.siteId == siteId;
    }).toList();
    yield List.unmodifiable(alerts);
  }

  @override
  Stream<Alert?> watchAlertById(String id) async* {
    try {
      yield _dataSource.alerts.firstWhere((a) => a.id == id);
    } catch (_) {
      yield null;
    }
  }
}
