import 'station.dart';
import 'station_activity_point.dart';
import 'detected_species.dart';

/// Presentation-safe domain read model that combines a Station with its
/// derived activity data from DetectionEvent records.
///
/// Built in StationsViewModel from Station + DetectionEvent data.
/// Never fetched directly from a repository.
/// Contains no Flutter UI types, no fl_chart types, no Firebase references.
class StationOverviewData {
  final Station station;

  /// Total number of detection events for this station.
  final int detectionCount;

  /// Daily aggregated detection counts for the past 7 days (oldest → newest).
  final List<StationActivityPoint> sevenDayActivity;

  /// The most recently detected species, or null if no recent detections.
  final DetectedSpecies? recentSpecies;

  /// Confidence score for the most recent detection, or null.
  final double? recentConfidence;

  StationOverviewData({
    required this.station,
    required this.detectionCount,
    required List<StationActivityPoint> sevenDayActivity,
    this.recentSpecies,
    this.recentConfidence,
  }) : sevenDayActivity = List.unmodifiable(sevenDayActivity);
}
