import '../../../domain/models/alert_severity.dart';
import '../../../domain/models/alert_status.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/dashboard/admin_dashboard_data.dart';
import '../../../domain/models/dashboard/dashboard_alert_item.dart';
import '../../../domain/models/dashboard/dashboard_system_status.dart';
import '../../../domain/models/dashboard/station_map_marker.dart';
import '../../../domain/models/dashboard/user_dashboard_data.dart';
import '../../../domain/models/site.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/dashboard_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockDashboardRepository implements DashboardRepository {
  final MockBaitGuardDataSource _dataSource;

  MockDashboardRepository(this._dataSource);

  @override
  Future<UserDashboardData> getUserDashboard({
    required AppUser user,
    String? siteId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (user.role != UserRole.viewer && user.role != UserRole.technician) {
      throw ArgumentError.value(user.role, 'user.role', 'Unsupported role');
    }

    final permittedSiteIds = _dataSource.sites
        .where((site) => user.siteAccessIds.contains(site.id))
        .map((site) => site.id)
        .toSet();
    if (permittedSiteIds.isEmpty) {
      throw StateError('Authenticated user has no matching permitted facility');
    }

    final selectedSiteId = siteId != null && permittedSiteIds.contains(siteId)
        ? siteId
        : permittedSiteIds.first;
    final snapshot = _dataSource.deploymentSnapshot;

    // Map specific stable alerts for User Dashboard
    final userAlertIds = const {'alert_1', 'alert_2', 'alert_3', 'alert_4'};
    final recentAlerts = _dataSource.alerts
        .where((a) => userAlertIds.contains(a.id))
        .where((alert) {
          final station = _dataSource.stations.firstWhere(
            (candidate) => candidate.id == alert.stationId,
          );
          return station.siteId == selectedSiteId;
        })
        .map((a) {
          final station = _dataSource.stations.firstWhere(
            (s) => s.id == a.stationId,
          );
          return DashboardAlertItem(
            id: a.id,
            title: a.description,
            location: station.locationDescription,
            timestamp: a.timestamp,
            severity: a.severity,
            type: a.type,
            status: a.status,
          );
        })
        .toList();

    // Deterministic marker layout from snapshot
    final markerCoordinates = snapshot.markerCoordinates;

    final mapMarkers = _dataSource.stations
        .where(
          (s) =>
              s.siteId == selectedSiteId && markerCoordinates.containsKey(s.id),
        )
        .map((s) {
          final coords = markerCoordinates[s.id]!;
          return StationMapMarker(
            stationId: s.id,
            name: s.name,
            normalizedX: coords['x']!,
            normalizedY: coords['y']!,
            status: s.status,
          );
        })
        .toList();

    return UserDashboardData(
      user: user,
      healthScore: snapshot.healthScore,
      healthScoreChange: snapshot.healthScoreChange,
      statusMessage: 'ALL SYSTEMS NOMINAL',
      lastUpdatedAt: DateTime.now(),
      stationMetrics: snapshot.stationMetrics,
      detectionsToday: snapshot.detectionsToday,
      activityChangePercentage: snapshot.userActivityChangePercentage,
      unreadAlertCount: snapshot.unreadAlertCount,
      speciesBreakdown: snapshot.speciesBreakdown,
      activitySeries: snapshot.activitySeries,
      mapMarkers: mapMarkers,
      facilityZones: snapshot.facilityZones,
      recentAlerts: recentAlerts,
    );
  }

  @override
  Future<AdminDashboardData> getAdminDashboard({
    required AppUser admin,
    String? siteId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (admin.role != UserRole.admin) {
      throw ArgumentError.value(admin.role, 'admin.role', 'Admin required');
    }

    final snapshot = _dataSource.deploymentSnapshot;

    // Filter available sites based on admin access
    final availableSites = _dataSource.sites
        .where((s) => admin.siteAccessIds.contains(s.id))
        .toList();
    final availableSiteIds = availableSites.map((site) => site.id).toSet();

    if (availableSites.isEmpty) {
      throw Exception('Admin has no site access');
    }

    // Determine selected site
    Site selectedSite = availableSites.first;
    if (siteId != null) {
      if (!admin.siteAccessIds.contains(siteId)) {
        throw StateError('Unauthorized site selection');
      }
      final matchingSites = availableSites.where((s) => s.id == siteId);
      if (matchingSites.isNotEmpty) {
        selectedSite = matchingSites.first;
      }
    }

    // Count new pending requests today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newRequestsToday = 0;
    for (final req in _dataSource.accessRequests) {
      final submittedAt = req.request.submittedAt;
      if (submittedAt == null) continue;
      final submittedDate = DateTime(
        submittedAt.year,
        submittedAt.month,
        submittedAt.day,
      );
      if (submittedDate.isAtSameMomentAs(today)) {
        newRequestsToday++;
      }
    }

    // Map representative recent alerts (admin uses all 6 seeded)
    final recentAlerts = _dataSource.alerts
        .where((alert) {
          final station = _dataSource.stations.firstWhere(
            (candidate) => candidate.id == alert.stationId,
          );
          return availableSiteIds.contains(station.siteId);
        })
        .map((a) {
          final station = _dataSource.stations.firstWhere(
            (s) => s.id == a.stationId,
          );
          return DashboardAlertItem(
            id: a.id,
            title: a.description,
            location: station.locationDescription,
            timestamp: a.timestamp,
            severity: a.severity,
            type: a.type,
            status: a.status,
          );
        })
        .toList();

    // Critical Unresolved Alert Count
    final criticalStationIds = <String>{};
    for (final a in _dataSource.alerts) {
      if (a.severity == AlertSeverity.critical &&
          (a.status == AlertStatus.open ||
              a.status == AlertStatus.pending ||
              a.status == AlertStatus.inReview)) {
        criticalStationIds.add(a.stationId);
      }
    }

    final markerCoordinates = snapshot.markerCoordinates;
    final mapMarkers = _dataSource.stations
        .where(
          (s) =>
              availableSiteIds.contains(s.siteId) &&
              markerCoordinates.containsKey(s.id),
        )
        .map((s) {
          final coords = markerCoordinates[s.id]!;
          return StationMapMarker(
            stationId: s.id,
            name: s.name,
            normalizedX: coords['x']!,
            normalizedY: coords['y']!,
            status: s.status,
          );
        })
        .toList();

    return AdminDashboardData(
      selectedSite: selectedSite,
      availableSites: availableSites,
      lastUpdatedAt: DateTime.now(),
      userCount: 28, // Canonical total user count
      pendingRequestCount: _dataSource.accessRequests.length,
      newPendingRequestCountToday: newRequestsToday,
      systemStatus: DashboardSystemStatus.healthy,
      systemHealthScore: snapshot.healthScore,
      healthScoreChange: snapshot.healthScoreChange,
      healthStatusMessage: 'All systems operating normally',
      stationMetrics: snapshot.stationMetrics,
      detectionsToday: snapshot.detectionsToday,
      detectionsChangePercentage: snapshot.adminDetectionsChangePercentage,
      criticalAlertCount: criticalStationIds.length,
      unreadAlertCount: snapshot.unreadAlertCount,
      totalAlertCount: 12, // Canonical total alert count
      recentAlerts: recentAlerts,
      activitySeries: snapshot.activitySeries,
      speciesBreakdown: snapshot.speciesBreakdown,
      mapMarkers: mapMarkers,
      facilityZones: snapshot.facilityZones,
    );
  }

  @override
  Stream<UserDashboardData> watchUserDashboard({
    required AppUser user,
    String? siteId,
  }) async* {
    yield await getUserDashboard(user: user, siteId: siteId);
  }

  @override
  Stream<AdminDashboardData> watchAdminDashboard({
    required AppUser admin,
    String? siteId,
  }) async* {
    yield await getAdminDashboard(admin: admin, siteId: siteId);
  }
}
