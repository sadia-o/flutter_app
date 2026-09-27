import 'detected_species.dart';

enum DetectionEventStatus { open, pending, resolved }

class DetectionEvent {
  final String id;
  final String stationId;
  final DateTime timestamp;
  final DetectedSpecies species;
  final double? confidenceScore;
  final String? evidenceImageUrl;
  final DetectionEventStatus status;
  final String? alertId;

  const DetectionEvent({
    required this.id,
    required this.stationId,
    required this.timestamp,
    required this.species,
    this.confidenceScore,
    this.evidenceImageUrl,
    this.status = DetectionEventStatus.open,
    this.alertId,
  });
}
