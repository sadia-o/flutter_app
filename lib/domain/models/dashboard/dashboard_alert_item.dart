import '../alert_severity.dart';
import '../alert_status.dart';
import '../alert_type.dart';

class DashboardAlertItem {
  final String id;
  final String title;
  final String location;
  final DateTime timestamp;
  final AlertSeverity severity;
  final AlertType type;
  final AlertStatus status;

  const DashboardAlertItem({
    required this.id,
    required this.title,
    required this.location,
    required this.timestamp,
    required this.severity,
    required this.type,
    required this.status,
  });
}
