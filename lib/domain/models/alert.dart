import 'alert_type.dart';
import 'alert_severity.dart';
import 'alert_status.dart';

class Alert {
  final String id;
  final String stationId;
  final AlertType type;
  final AlertSeverity severity;
  final AlertStatus status;
  final DateTime timestamp;
  final String description;

  // New fields for complete Alerts feature
  final bool isRead;
  final DateTime? snoozedUntil;
  final String? assignedTechnicianId;
  final DateTime? resolvedAt;
  final String? resolvedByUserId;
  final String? detectionEventId;
  final DateTime? dismissedAt;
  final String? dismissedByUserId;

  const Alert({
    required this.id,
    required this.stationId,
    required this.type,
    required this.severity,
    required this.status,
    required this.timestamp,
    required this.description,
    this.isRead = false,
    this.snoozedUntil,
    this.assignedTechnicianId,
    this.resolvedAt,
    this.resolvedByUserId,
    this.detectionEventId,
    this.dismissedAt,
    this.dismissedByUserId,
  });

  Alert copyWith({
    String? id,
    String? stationId,
    AlertType? type,
    AlertSeverity? severity,
    AlertStatus? status,
    DateTime? timestamp,
    String? description,
    bool? isRead,
    DateTime? snoozedUntil,
    String? assignedTechnicianId,
    DateTime? resolvedAt,
    String? resolvedByUserId,
    String? detectionEventId,
    DateTime? dismissedAt,
    String? dismissedByUserId,
    bool clearSnoozedUntil = false,
    bool clearAssignedTechnicianId = false,
  }) {
    return Alert(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      isRead: isRead ?? this.isRead,
      snoozedUntil: clearSnoozedUntil
          ? null
          : (snoozedUntil ?? this.snoozedUntil),
      assignedTechnicianId: clearAssignedTechnicianId
          ? null
          : (assignedTechnicianId ?? this.assignedTechnicianId),
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedByUserId: resolvedByUserId ?? this.resolvedByUserId,
      detectionEventId: detectionEventId ?? this.detectionEventId,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      dismissedByUserId: dismissedByUserId ?? this.dismissedByUserId,
    );
  }
}
