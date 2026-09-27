import '../models/alert.dart';

abstract class AlertRepository {
  Future<List<Alert>> getAlerts({required String siteId});
  Future<Alert> getAlertById(String id);
  Future<Alert> markAlertRead({required String alertId});
  Future<Alert> resolveAlert({
    required String alertId,
    required String resolvedByUserId,
  });
  Future<Alert> snoozeAlert({required String alertId, required DateTime until});
  Future<Alert> assignAlert({
    required String alertId,
    required String technicianId,
  });
  Future<Alert> dismissAlert({
    required String alertId,
    required String dismissedByUserId,
  });

  /// Reactive streams for live alert updates
  Stream<List<Alert>> watchAlerts({required String siteId}) =>
      Stream.fromFuture(getAlerts(siteId: siteId));

  Stream<Alert?> watchAlertById(String id) => Stream.fromFuture(
    getAlertById(id).then<Alert?>((a) => a).catchError((_) => null),
  );

  /// Indicates whether the repository supports client-side alert mutations
  /// (e.g. resolve, snooze, dismiss).
  bool get supportsMutations => false;
}
