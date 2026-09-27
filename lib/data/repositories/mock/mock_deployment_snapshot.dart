import '../../../domain/models/dashboard/activity_data_point.dart';
import '../../../domain/models/dashboard/dashboard_species.dart';
import '../../../domain/models/dashboard/species_breakdown_item.dart';
import '../../../domain/models/dashboard/station_summary_metrics.dart';
import '../../../domain/models/dashboard/facility_map_zone.dart';

class MockDeploymentSnapshot {
  final StationSummaryMetrics stationMetrics;
  final int detectionsToday;
  final int healthScore;
  final int healthScoreChange;
  final double userActivityChangePercentage;
  final double adminDetectionsChangePercentage;
  final int unreadAlertCount;
  final List<SpeciesBreakdownItem> speciesBreakdown;
  final List<ActivityDataPoint> activitySeries;
  final List<FacilityMapZone> facilityZones;
  final Map<String, Map<String, double>> markerCoordinates;

  MockDeploymentSnapshot({
    required this.stationMetrics,
    required this.detectionsToday,
    required this.healthScore,
    required this.healthScoreChange,
    required this.userActivityChangePercentage,
    required this.adminDetectionsChangePercentage,
    required this.unreadAlertCount,
    required List<SpeciesBreakdownItem> speciesBreakdown,
    required List<ActivityDataPoint> activitySeries,
    required List<FacilityMapZone> facilityZones,
    required Map<String, Map<String, double>> markerCoordinates,
  }) : speciesBreakdown = List.unmodifiable(speciesBreakdown),
       activitySeries = List.unmodifiable(activitySeries),
       facilityZones = List.unmodifiable(facilityZones),
       markerCoordinates = Map.unmodifiable(markerCoordinates);

  factory MockDeploymentSnapshot.seeded({DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    return MockDeploymentSnapshot(
      stationMetrics: const StationSummaryMetrics(
        totalCount: 120,
        activeCount: 118,
        offlineCount: 2,
        refillNeededCount: 8,
      ),
      detectionsToday: 42,
      healthScore: 87,
      healthScoreChange: 3,
      userActivityChangePercentage: 23.0,
      adminDetectionsChangePercentage: 12.0,
      unreadAlertCount: 3,
      speciesBreakdown: const [
        SpeciesBreakdownItem(
          species: DashboardSpecies.rat,
          count: 50,
          percentage: 58.0,
        ),
        SpeciesBreakdownItem(
          species: DashboardSpecies.mouse,
          count: 25,
          percentage: 29.0,
        ),
        SpeciesBreakdownItem(
          species: DashboardSpecies.other,
          count: 12,
          percentage: 13.0,
        ),
      ],
      activitySeries: [
        ActivityDataPoint(
          time: now.subtract(const Duration(hours: 24)),
          count: 10,
        ),
        ActivityDataPoint(
          time: now.subtract(const Duration(hours: 21)),
          count: 15,
        ),
        ActivityDataPoint(
          time: now.subtract(const Duration(hours: 18)),
          count: 35,
        ),
        ActivityDataPoint(
          time: now.subtract(const Duration(hours: 15)),
          count: 25,
        ),
        ActivityDataPoint(
          time: now.subtract(const Duration(hours: 12)),
          count: 20,
        ),
        ActivityDataPoint(
          time: now.subtract(const Duration(hours: 9)),
          count: 30,
        ),
        ActivityDataPoint(
          time: now.subtract(const Duration(hours: 6)),
          count: 45,
        ), // Peak
        ActivityDataPoint(
          time: now.subtract(const Duration(hours: 3)),
          count: 20,
        ),
        ActivityDataPoint(time: now, count: 10),
      ],
      facilityZones: const [
        FacilityMapZone(
          id: 'zone_a',
          label: 'Zone A',
          left: 0.1,
          top: 0.1,
          width: 0.4,
          height: 0.3,
          labelX: 0.15,
          labelY: 0.15,
        ),
        FacilityMapZone(
          id: 'zone_b',
          label: 'Zone B',
          left: 0.5,
          top: 0.1,
          width: 0.4,
          height: 0.3,
          labelX: 0.55,
          labelY: 0.15,
        ),
        FacilityMapZone(
          id: 'zone_c',
          label: 'Zone C',
          left: 0.1,
          top: 0.4,
          width: 0.8,
          height: 0.5,
          labelX: 0.15,
          labelY: 0.45,
        ),
      ],
      markerCoordinates: const {
        'RB-01': {
          'x': 0.35,
          'y': 0.25,
        }, // Adjusted to avoid Zone A label (0.15, 0.15)
        'RB-03': {
          'x': 0.75,
          'y': 0.25,
        }, // Adjusted to avoid Zone B label (0.55, 0.15)
        'RB-05': {
          'x': 0.5,
          'y': 0.6,
        }, // Adjusted to avoid Zone C label (0.15, 0.45)
        'RB-07': {'x': 0.25, 'y': 0.75}, // Safe in Zone C bottom left
        'RB-08': {'x': 0.75, 'y': 0.75}, // Safe in Zone C bottom right
        'RB-09': {'x': 0.15, 'y': 0.6}, // Left side, safe from top-left label
        'RB-12': {'x': 0.85, 'y': 0.6}, // Right side
      },
    );
  }
}
