import 'dart:async';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/dashboard/activity_data_point.dart';
import '../../../domain/models/dashboard/admin_dashboard_data.dart';
import '../../../domain/models/dashboard/dashboard_alert_item.dart';
import '../../../domain/models/dashboard/dashboard_system_status.dart';
import '../../../domain/models/dashboard/facility_map_zone.dart';
import '../../../domain/models/dashboard/species_breakdown_item.dart';
import '../../../domain/models/dashboard/station_map_marker.dart';
import '../../../domain/models/dashboard/station_summary_metrics.dart';
import '../../../domain/models/dashboard/user_dashboard_data.dart';
import '../../../domain/models/dashboard/dashboard_species.dart';
import '../../../domain/models/alert_status.dart';
import '../../../domain/models/alert_severity.dart';
import '../../../domain/models/site.dart';
import '../../../domain/models/station.dart';
import '../../../domain/models/station_status.dart';
import '../../../domain/repositories/dashboard_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'realtime_station_data_source.dart';

class RealtimeDashboardRepository implements DashboardRepository {
  final RealtimeStationDataSource _dataSource;
  final UserRepository? _userRepository;

  RealtimeDashboardRepository(
    this._dataSource, {
    UserRepository? userRepository,
  }) : _userRepository = userRepository;

  @override
  Future<UserDashboardData> getUserDashboard({
    required AppUser user,
    String? siteId,
  }) async {
    final selectedSiteId =
        siteId ??
        (user.siteAccessIds.isNotEmpty ? user.siteAccessIds.first : null);

    if (selectedSiteId == null ||
        !user.siteAccessIds.contains(selectedSiteId) ||
        selectedSiteId != RealtimeStationDataSource.kPilotFacilityId) {
      return _buildEmptyUserDashboard(user, selectedSiteId ?? '');
    }

    final station = await _dataSource.fetchStation(
      RealtimeStationDataSource.kPilotStationId,
    );
    final events = await _dataSource.fetchStationEvents(
      RealtimeStationDataSource.kPilotStationId,
    );
    final alerts = await _dataSource.fetchAlerts(siteId: selectedSiteId);

    final metrics = _computeStationMetrics(station);
    final now = DateTime.now();

    final detectionsToday = events.where((e) {
      final local = e.timestamp.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).length;

    final activitySeries = _compute7DayActivitySeries(events, now);
    final speciesBreakdown = _computeSpeciesBreakdown(events);
    final recentAlertItems = _mapRecentAlerts(alerts, station);
    final mapMarkers = _buildMapMarkers(station);
    final facilityZones = _buildFacilityZones(station);

    int healthScore;
    String healthStatusMessage;
    if (station == null || station.status == StationStatus.offline) {
      healthScore = 0;
      healthStatusMessage = 'STATION OFFLINE';
    } else if (station.status == StationStatus.lowBait) {
      healthScore = station.baitPercentage.round().clamp(0, 100);
      healthStatusMessage = 'LOW BAIT ATTENTION';
    } else {
      healthScore = ((station.baitPercentage + station.batteryPercentage) / 2)
          .round()
          .clamp(0, 100);
      healthStatusMessage = 'ALL SYSTEMS NOMINAL';
    }

    return UserDashboardData(
      user: user,
      healthScore: healthScore,
      healthScoreChange: 0, // No unmeasured arbitrary changes
      statusMessage: healthStatusMessage,
      lastUpdatedAt: DateTime.now(),
      stationMetrics: metrics,
      detectionsToday: detectionsToday,
      activityChangePercentage: 0.0,
      unreadAlertCount: alerts
          .where((a) => a.status == AlertStatus.open)
          .length,
      speciesBreakdown: speciesBreakdown,
      activitySeries: activitySeries,
      mapMarkers: mapMarkers,
      facilityZones: facilityZones,
      recentAlerts: recentAlertItems,
    );
  }

  @override
  Future<AdminDashboardData> getAdminDashboard({
    required AppUser admin,
    String? siteId,
  }) async {
    final selectedSiteId =
        siteId ??
        (admin.siteAccessIds.isNotEmpty ? admin.siteAccessIds.first : null);

    final availableSites = admin.siteAccessIds
        .map(
          (id) => Site(
            id: id,
            name: id == RealtimeStationDataSource.kPilotFacilityId
                ? 'Warehouse A'
                : id,
            location: 'Main Site',
          ),
        )
        .toList();

    if (selectedSiteId == null ||
        !admin.siteAccessIds.contains(selectedSiteId) ||
        selectedSiteId != RealtimeStationDataSource.kPilotFacilityId) {
      final fallbackSite = availableSites.isNotEmpty
          ? availableSites.first
          : const Site(id: '', name: 'No Facility', location: '');
      return _buildEmptyAdminDashboard(admin, fallbackSite, availableSites);
    }

    final selectedSite = availableSites.firstWhere(
      (s) => s.id == selectedSiteId,
      orElse: () => availableSites.first,
    );

    final station = await _dataSource.fetchStation(
      RealtimeStationDataSource.kPilotStationId,
    );
    final events = await _dataSource.fetchStationEvents(
      RealtimeStationDataSource.kPilotStationId,
    );
    final alerts = await _dataSource.fetchAlerts(siteId: selectedSiteId);

    final metrics = _computeStationMetrics(station);
    final now = DateTime.now();

    final detectionsToday = events.where((e) {
      final local = e.timestamp.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).length;

    final activitySeries = _compute7DayActivitySeries(events, now);
    final speciesBreakdown = _computeSpeciesBreakdown(events);
    final recentAlertItems = _mapRecentAlerts(alerts, station);
    final mapMarkers = _buildMapMarkers(station);
    final facilityZones = _buildFacilityZones(station);

    int healthScore;
    String healthStatusMessage;
    DashboardSystemStatus systemStatus;

    if (station == null || station.status == StationStatus.offline) {
      healthScore = 0;
      healthStatusMessage = 'STATION OFFLINE';
      systemStatus = DashboardSystemStatus.warning;
    } else if (station.status == StationStatus.lowBait) {
      healthScore = station.baitPercentage.round().clamp(0, 100);
      healthStatusMessage = 'LOW BAIT ATTENTION';
      systemStatus = DashboardSystemStatus.warning;
    } else if (station.status == StationStatus.alert) {
      healthScore = station.batteryPercentage.round().clamp(0, 100);
      healthStatusMessage = 'RODENT ACTIVITY DETECTED';
      systemStatus = DashboardSystemStatus.critical;
    } else {
      healthScore = ((station.baitPercentage + station.batteryPercentage) / 2)
          .round()
          .clamp(0, 100);
      healthStatusMessage = 'ALL SYSTEMS NOMINAL';
      systemStatus = DashboardSystemStatus.healthy;
    }

    int realUserCount = 0;
    final userRepo = _userRepository;
    if (userRepo != null) {
      try {
        final users = await userRepo.getUsers();
        realUserCount = users.length;
      } catch (_) {
        realUserCount = 0;
      }
    }

    final openAlerts = alerts
        .where((a) => a.status == AlertStatus.open)
        .toList();
    final criticalCount = openAlerts
        .where((a) => a.severity == AlertSeverity.critical)
        .length;

    return AdminDashboardData(
      selectedSite: selectedSite,
      availableSites: availableSites,
      lastUpdatedAt: DateTime.now(),
      userCount: realUserCount,
      pendingRequestCount: 0,
      newPendingRequestCountToday: 0,
      systemStatus: systemStatus,
      systemHealthScore: healthScore,
      healthScoreChange: 0,
      healthStatusMessage: healthStatusMessage,
      stationMetrics: metrics,
      detectionsToday: detectionsToday,
      detectionsChangePercentage: 0.0,
      criticalAlertCount: criticalCount,
      unreadAlertCount: openAlerts.where((a) => !a.isRead).length,
      totalAlertCount: alerts.length,
      recentAlerts: recentAlertItems,
      activitySeries: activitySeries,
      speciesBreakdown: speciesBreakdown,
      mapMarkers: mapMarkers,
      facilityZones: facilityZones,
    );
  }

  @override
  Stream<UserDashboardData> watchUserDashboard({
    required AppUser user,
    String? siteId,
  }) {
    late StreamController<UserDashboardData> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;

    controller = StreamController<UserDashboardData>.broadcast(
      onListen: () async {
        try {
          final initial = await getUserDashboard(user: user, siteId: siteId);
          if (!controller.isClosed) controller.add(initial);
        } catch (e) {
          if (!controller.isClosed) controller.addError(e);
        }

        void emitUpdate() async {
          try {
            final updated = await getUserDashboard(user: user, siteId: siteId);
            if (!controller.isClosed) controller.add(updated);
          } catch (e) {
            if (!controller.isClosed) controller.addError(e);
          }
        }

        sub1 = _dataSource.stationStream.listen((_) => emitUpdate());
        sub2 = _dataSource.eventsStream.listen((_) => emitUpdate());
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<AdminDashboardData> watchAdminDashboard({
    required AppUser admin,
    String? siteId,
  }) {
    late StreamController<AdminDashboardData> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;

    controller = StreamController<AdminDashboardData>.broadcast(
      onListen: () async {
        try {
          final initial = await getAdminDashboard(admin: admin, siteId: siteId);
          if (!controller.isClosed) controller.add(initial);
        } catch (e) {
          if (!controller.isClosed) controller.addError(e);
        }

        void emitUpdate() async {
          try {
            final updated = await getAdminDashboard(
              admin: admin,
              siteId: siteId,
            );
            if (!controller.isClosed) controller.add(updated);
          } catch (e) {
            if (!controller.isClosed) controller.addError(e);
          }
        }

        sub1 = _dataSource.stationStream.listen((_) => emitUpdate());
        sub2 = _dataSource.eventsStream.listen((_) => emitUpdate());
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
      },
    );

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Metric and Visualization Computation Helpers
  // ---------------------------------------------------------------------------

  StationSummaryMetrics _computeStationMetrics(Station? station) {
    if (station == null) {
      return const StationSummaryMetrics(
        totalCount: 0,
        activeCount: 0,
        offlineCount: 0,
        refillNeededCount: 0,
      );
    }

    final isOnline = station.status != StationStatus.offline;
    final isLowBait = station.status == StationStatus.lowBait;

    return StationSummaryMetrics(
      totalCount: 1,
      activeCount: isOnline ? 1 : 0,
      offlineCount: isOnline ? 0 : 1,
      refillNeededCount: isLowBait ? 1 : 0,
    );
  }

  List<ActivityDataPoint> _compute7DayActivitySeries(
    List<dynamic> events,
    DateTime now,
  ) {
    final points = <ActivityDataPoint>[];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));

      final count = events.where((e) {
        final local = (e.timestamp as DateTime).toLocal();
        return local.year == date.year &&
            local.month == date.month &&
            local.day == date.day;
      }).length;

      points.add(ActivityDataPoint(time: date, count: count));
    }

    return points;
  }

  List<SpeciesBreakdownItem> _computeSpeciesBreakdown(List<dynamic> events) {
    if (events.isEmpty) {
      return const [
        SpeciesBreakdownItem(
          species: DashboardSpecies.rat,
          count: 0,
          percentage: 0.0,
        ),
        SpeciesBreakdownItem(
          species: DashboardSpecies.mouse,
          count: 0,
          percentage: 0.0,
        ),
        SpeciesBreakdownItem(
          species: DashboardSpecies.other,
          count: 0,
          percentage: 0.0,
        ),
      ];
    }

    return [
      SpeciesBreakdownItem(
        species: DashboardSpecies.rat,
        count: events.length,
        percentage: 100.0,
      ),
      const SpeciesBreakdownItem(
        species: DashboardSpecies.mouse,
        count: 0,
        percentage: 0.0,
      ),
      const SpeciesBreakdownItem(
        species: DashboardSpecies.other,
        count: 0,
        percentage: 0.0,
      ),
    ];
  }

  List<DashboardAlertItem> _mapRecentAlerts(
    List<dynamic> alerts,
    Station? station,
  ) {
    return alerts.take(5).map((a) {
      return DashboardAlertItem(
        id: a.id as String,
        title: a.description as String,
        location: station?.locationDescription ?? 'Warehouse A',
        timestamp: a.timestamp as DateTime,
        severity: a.severity,
        type: a.type,
        status: a.status,
      );
    }).toList();
  }

  List<StationMapMarker> _buildMapMarkers(Station? station) {
    if (station == null) return const [];
    return [
      StationMapMarker(
        stationId: station.id,
        name: station.name,
        normalizedX: 0.35,
        normalizedY: 0.45,
        status: station.status,
      ),
    ];
  }

  List<FacilityMapZone> _buildFacilityZones(Station? station) {
    return const [
      FacilityMapZone(
        id: 'zone_a',
        label: 'Zone A',
        left: 0.1,
        top: 0.1,
        width: 0.8,
        height: 0.8,
        labelX: 0.15,
        labelY: 0.15,
      ),
    ];
  }

  UserDashboardData _buildEmptyUserDashboard(AppUser user, String siteId) {
    return UserDashboardData(
      user: user,
      healthScore: 0,
      healthScoreChange: 0,
      statusMessage: 'NO ACTIVE TELEMETRY',
      lastUpdatedAt: DateTime.now(),
      stationMetrics: const StationSummaryMetrics(
        totalCount: 0,
        activeCount: 0,
        offlineCount: 0,
        refillNeededCount: 0,
      ),
      detectionsToday: 0,
      activityChangePercentage: 0.0,
      unreadAlertCount: 0,
      speciesBreakdown: const [],
      activitySeries: const [],
      mapMarkers: const [],
      facilityZones: const [],
      recentAlerts: const [],
    );
  }

  AdminDashboardData _buildEmptyAdminDashboard(
    AppUser admin,
    Site selectedSite,
    List<Site> availableSites,
  ) {
    return AdminDashboardData(
      selectedSite: selectedSite,
      availableSites: availableSites,
      lastUpdatedAt: DateTime.now(),
      userCount: 0,
      pendingRequestCount: 0,
      newPendingRequestCountToday: 0,
      systemStatus: DashboardSystemStatus.healthy,
      systemHealthScore: 0,
      healthScoreChange: 0,
      healthStatusMessage: 'NO ACTIVE TELEMETRY',
      stationMetrics: const StationSummaryMetrics(
        totalCount: 0,
        activeCount: 0,
        offlineCount: 0,
        refillNeededCount: 0,
      ),
      detectionsToday: 0,
      detectionsChangePercentage: 0.0,
      criticalAlertCount: 0,
      unreadAlertCount: 0,
      totalAlertCount: 0,
      recentAlerts: const [],
      activitySeries: const [],
      speciesBreakdown: const [],
      mapMarkers: const [],
      facilityZones: const [],
    );
  }
}
