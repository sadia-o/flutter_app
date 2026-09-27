import '../site.dart';
import 'activity_data_point.dart';
import 'dashboard_alert_item.dart';
import 'dashboard_system_status.dart';
import 'facility_map_zone.dart';
import 'species_breakdown_item.dart';
import 'station_map_marker.dart';
import 'station_summary_metrics.dart';

class AdminDashboardData {
  // Facility
  final Site selectedSite;
  final List<Site> availableSites;
  final DateTime lastUpdatedAt;

  // Admin Overview
  final int userCount;
  final int pendingRequestCount;
  final int newPendingRequestCountToday;
  final DashboardSystemStatus systemStatus;

  // Health
  final int systemHealthScore;
  final int healthScoreChange;
  final String healthStatusMessage;
  final StationSummaryMetrics stationMetrics;

  // Detections
  final int detectionsToday;
  final double detectionsChangePercentage;

  // Alerts
  final int criticalAlertCount;
  final int unreadAlertCount;
  final int totalAlertCount;
  final List<DashboardAlertItem> recentAlerts;

  // Charts and Maps
  final List<ActivityDataPoint> activitySeries;
  final List<SpeciesBreakdownItem> speciesBreakdown;
  final List<StationMapMarker> mapMarkers;
  final List<FacilityMapZone> facilityZones;

  AdminDashboardData({
    required this.selectedSite,
    required List<Site> availableSites,
    required this.lastUpdatedAt,
    required this.userCount,
    required this.pendingRequestCount,
    required this.newPendingRequestCountToday,
    required this.systemStatus,
    required this.systemHealthScore,
    required this.healthScoreChange,
    required this.healthStatusMessage,
    required this.stationMetrics,
    required this.detectionsToday,
    required this.detectionsChangePercentage,
    required this.criticalAlertCount,
    required this.unreadAlertCount,
    required this.totalAlertCount,
    required List<DashboardAlertItem> recentAlerts,
    required List<ActivityDataPoint> activitySeries,
    required List<SpeciesBreakdownItem> speciesBreakdown,
    required List<StationMapMarker> mapMarkers,
    required List<FacilityMapZone> facilityZones,
  }) : availableSites = List.unmodifiable(availableSites),
       recentAlerts = List.unmodifiable(recentAlerts),
       activitySeries = List.unmodifiable(activitySeries),
       speciesBreakdown = List.unmodifiable(speciesBreakdown),
       mapMarkers = List.unmodifiable(mapMarkers),
       facilityZones = List.unmodifiable(facilityZones);

  int get facilityCount => availableSites.length;

  AdminDashboardData withPendingRequests({
    required int pendingRequestCount,
    required int newPendingRequestCountToday,
  }) {
    return AdminDashboardData(
      selectedSite: selectedSite,
      availableSites: availableSites,
      lastUpdatedAt: lastUpdatedAt,
      userCount: userCount,
      pendingRequestCount: pendingRequestCount,
      newPendingRequestCountToday: newPendingRequestCountToday,
      systemStatus: systemStatus,
      systemHealthScore: systemHealthScore,
      healthScoreChange: healthScoreChange,
      healthStatusMessage: healthStatusMessage,
      stationMetrics: stationMetrics,
      detectionsToday: detectionsToday,
      detectionsChangePercentage: detectionsChangePercentage,
      criticalAlertCount: criticalAlertCount,
      unreadAlertCount: unreadAlertCount,
      totalAlertCount: totalAlertCount,
      recentAlerts: recentAlerts,
      activitySeries: activitySeries,
      speciesBreakdown: speciesBreakdown,
      mapMarkers: mapMarkers,
      facilityZones: facilityZones,
    );
  }
}
