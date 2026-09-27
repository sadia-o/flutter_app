import '../app_user.dart';
import 'activity_data_point.dart';
import 'dashboard_alert_item.dart';
import 'species_breakdown_item.dart';
import 'station_map_marker.dart';
import 'station_summary_metrics.dart';
import 'facility_map_zone.dart';

class UserDashboardData {
  final AppUser user;
  final int healthScore;
  final int healthScoreChange;
  final String statusMessage;
  final DateTime lastUpdatedAt;
  final StationSummaryMetrics stationMetrics;
  final int detectionsToday;
  final double activityChangePercentage;
  final int unreadAlertCount;
  final List<SpeciesBreakdownItem> speciesBreakdown;
  final List<ActivityDataPoint> activitySeries;
  final List<StationMapMarker> mapMarkers;
  final List<FacilityMapZone> facilityZones;
  final List<DashboardAlertItem> recentAlerts;

  UserDashboardData({
    required this.user,
    required this.healthScore,
    required this.healthScoreChange,
    required this.statusMessage,
    required this.lastUpdatedAt,
    required this.stationMetrics,
    required this.detectionsToday,
    required this.activityChangePercentage,
    required this.unreadAlertCount,
    required List<SpeciesBreakdownItem> speciesBreakdown,
    required List<ActivityDataPoint> activitySeries,
    required List<StationMapMarker> mapMarkers,
    required List<FacilityMapZone> facilityZones,
    required List<DashboardAlertItem> recentAlerts,
  }) : speciesBreakdown = List.unmodifiable(speciesBreakdown),
       activitySeries = List.unmodifiable(activitySeries),
       mapMarkers = List.unmodifiable(mapMarkers),
       facilityZones = List.unmodifiable(facilityZones),
       recentAlerts = List.unmodifiable(recentAlerts);
}
