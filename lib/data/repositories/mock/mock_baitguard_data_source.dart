import '../../../domain/models/access_request.dart';
import '../../../domain/models/access_request_record.dart';
import '../../../domain/models/alert.dart';
import '../../../domain/models/alert_severity.dart';
import '../../../domain/models/alert_status.dart';
import '../../../domain/models/alert_type.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/detected_species.dart';
import '../../../domain/models/detection_event.dart';
import '../../../domain/models/register_station_request.dart';
import '../../../domain/models/report_models.dart';
import '../../../domain/models/site.dart';
import '../../../domain/models/station.dart';
import '../../../domain/models/station_status.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/models/user_settings.dart';
import 'mock_deployment_snapshot.dart';

class MockBaitGuardDataSource {
  final MockDeploymentSnapshot deploymentSnapshot;

  final List<Site> _sites = [];
  final List<AppUser> _users = [];
  final List<Station> _stations = [];
  final List<Alert> _alerts = [];
  final List<AccessRequestRecord> _accessRequests = [];
  final List<DetectionEvent> _detectionEvents = [];
  final List<ReportExport> _reportExports = [];
  final Map<String, UserSettings> _userSettings = {};

  int _nextAccessRequestNumber = 1;

  MockBaitGuardDataSource({
    required this.deploymentSnapshot,
    List<Site>? sites,
    List<AppUser>? users,
    List<Station>? stations,
    List<Alert>? alerts,
    List<AccessRequestRecord>? accessRequests,
    List<DetectionEvent>? detectionEvents,
    List<ReportExport>? reportExports,
  }) {
    if (sites != null) _sites.addAll(sites);
    if (users != null) _users.addAll(users);
    if (stations != null) _stations.addAll(stations);
    if (alerts != null) _alerts.addAll(alerts);
    if (accessRequests != null) _accessRequests.addAll(accessRequests);
    if (detectionEvents != null) _detectionEvents.addAll(detectionEvents);
    if (reportExports != null) _reportExports.addAll(reportExports);

    int highestReqId = 0;
    for (final req in _accessRequests) {
      if (req.id.startsWith('req_')) {
        final numPart = int.tryParse(req.id.substring(4));
        if (numPart != null && numPart > highestReqId) {
          highestReqId = numPart;
        }
      }
    }
    _nextAccessRequestNumber = highestReqId + 1;
  }

  factory MockBaitGuardDataSource.seeded({DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    return MockBaitGuardDataSource(
      deploymentSnapshot: MockDeploymentSnapshot.seeded(referenceTime: now),
      sites: const [
        Site(id: 'site_1', name: 'Warehouse A', location: 'North District'),
        Site(id: 'site_2', name: 'Warehouse B', location: 'North District'),
        Site(
          id: 'site_3',
          name: 'Distribution Center',
          location: 'East District',
        ),
        Site(id: 'site_4', name: 'Cold Storage', location: 'South District'),
        Site(
          id: 'site_5',
          name: 'Manufacturing Plant',
          location: 'West District',
        ),
      ],
      users: [
        AppUser(
          id: 'admin_1',
          name: 'Alex Rivera',
          email: 'admin@baitguard.com',
          role: UserRole.admin,
          isActive: true,
          siteAccessIds: ['site_1', 'site_2', 'site_3', 'site_4', 'site_5'],
          phoneNumber: '+1 555 987 6543',
        ),
        AppUser(
          id: 'viewer_1',
          name: 'Alex Rivera',
          email: 'user@baitguard.com',
          role: UserRole.viewer,
          isActive: true,
          siteAccessIds: ['site_1'],
        ),
        AppUser(
          id: 'tech_1',
          name: 'Ahmed Khan',
          email: 'technician@baitguard.com',
          role: UserRole.technician,
          isActive: true,
          siteAccessIds: ['site_1'],
        ),
        AppUser(
          id: 'inactive_1',
          name: 'Inactive User',
          email: 'inactive@baitguard.com',
          role: UserRole.viewer,
          isActive: false,
          siteAccessIds: [],
        ),
      ],
      stations: [
        Station(
          id: 'RB-01',
          name: 'RB-01 — Kitchen area',
          siteId: 'site_1',
          locationDescription: 'Kitchen area',
          status: StationStatus.online,
          baitPercentage: 60.0,
          batteryPercentage: 95.0,
          temperature: 24.0,
          humidity: 40.0,
          isTampered: false,
          lastSeen: now.subtract(const Duration(minutes: 2)),
          hasCamera: true,
        ),
        Station(
          id: 'RB-03',
          name: 'RB-03 — Cold storage',
          siteId: 'site_1',
          locationDescription: 'Cold storage',
          status: StationStatus.lowBait,
          baitPercentage: 18.0,
          batteryPercentage: 85.0,
          temperature: 4.5,
          humidity: 55.0,
          isTampered: false,
          lastSeen: now.subtract(const Duration(minutes: 15)),
          hasCamera: false,
        ),
        Station(
          id: 'RB-05',
          name: 'RB-05 — Loading bay',
          siteId: 'site_1',
          locationDescription: 'Loading bay',
          status: StationStatus.online,
          baitPercentage: 45.0,
          batteryPercentage: 80.0,
          temperature: 22.0,
          humidity: 50.0,
          isTampered: false,
          lastSeen: now.subtract(const Duration(minutes: 3)),
          hasCamera: false,
        ),
        Station(
          id: 'RB-07',
          name: 'RB-07 — Warehouse B',
          siteId: 'site_1',
          locationDescription: 'Warehouse B',
          status: StationStatus.alert,
          baitPercentage: 18.0,
          batteryPercentage: 82.0,
          temperature: 24.0,
          humidity: 61.0,
          isTampered: false,
          lastSeen: now.subtract(const Duration(minutes: 5)),
          hasCamera: true,
        ),
        Station(
          id: 'RB-08',
          name: 'RB-08 — East corridor',
          siteId: 'site_1',
          locationDescription: 'East corridor',
          status: StationStatus.online,
          baitPercentage: 50.0,
          batteryPercentage: 70.0,
          temperature: 22.0,
          humidity: 48.0,
          isTampered: false,
          lastSeen: now.subtract(const Duration(minutes: 8)),
          hasCamera: false,
        ),
        Station(
          id: 'RB-09',
          name: 'RB-09 — Parking lot',
          siteId: 'site_1',
          locationDescription: 'Parking lot',
          status: StationStatus.offline,
          baitPercentage: 0.0,
          batteryPercentage: 0.0,
          isTampered: false,
          lastSeen: now.subtract(const Duration(hours: 48)),
          hasCamera: false,
        ),
        Station(
          id: 'RB-12',
          name: 'RB-12 — Main entrance',
          siteId: 'site_1',
          locationDescription: 'Main entrance',
          status: StationStatus.alert,
          baitPercentage: 95.0,
          batteryPercentage: 99.0,
          temperature: 21.0,
          humidity: 50.0,
          isTampered: true,
          lastSeen: now.subtract(const Duration(hours: 24)),
          hasCamera: true,
        ),
      ],
      alerts: [
        Alert(
          id: 'alert_1',
          stationId: 'RB-07',
          type: AlertType.rodent,
          severity: AlertSeverity.critical,
          status: AlertStatus.open,
          timestamp: DateTime(now.year, now.month, now.day, 2, 13),
          description: 'Rat detected',
          detectionEventId: 'evt_rb07_1',
        ),
        Alert(
          id: 'alert_2',
          stationId: 'RB-03',
          type: AlertType.lowBait,
          severity: AlertSeverity.warning,
          status: AlertStatus.pending,
          timestamp: DateTime(now.year, now.month, now.day, 11, 45),
          description: 'Low bait (18%)',
        ),
        Alert(
          id: 'alert_3',
          stationId: 'RB-12',
          type: AlertType.tamper,
          severity: AlertSeverity.critical,
          status: AlertStatus.open,
          timestamp: now.subtract(const Duration(hours: 24)),
          description: 'Tamper detected',
        ),
        Alert(
          id: 'alert_4',
          stationId: 'RB-09',
          type: AlertType.stationOffline,
          severity: AlertSeverity.info,
          status: AlertStatus.inReview,
          timestamp: now.subtract(const Duration(hours: 48)),
          description: 'Station offline',
        ),
        Alert(
          id: 'alert_5',
          stationId: 'RB-01',
          type: AlertType.rodent,
          severity: AlertSeverity.warning,
          status: AlertStatus.resolved,
          timestamp: now.subtract(const Duration(days: 3, hours: 2)),
          description: 'Mouse detected',
        ),
        Alert(
          id: 'alert_6',
          stationId: 'RB-05',
          type: AlertType.lowBait,
          severity: AlertSeverity.info,
          status: AlertStatus.resolved,
          timestamp: now.subtract(const Duration(days: 4, hours: 10)),
          description: 'Low bait (25%)',
        ),
        Alert(
          id: 'alert_7',
          stationId: 'RB-08',
          type: AlertType.rodent,
          severity: AlertSeverity.warning,
          status: AlertStatus.resolved,
          timestamp: now.subtract(const Duration(days: 5, hours: 8)),
          description: 'Rat detected',
          detectionEventId: 'evt_rb08_1',
        ),
        Alert(
          id: 'alert_8',
          stationId: 'RB-07',
          type: AlertType.tamper,
          severity: AlertSeverity.warning,
          status: AlertStatus.resolved,
          timestamp: now.subtract(const Duration(days: 6, hours: 4)),
          description: 'Tamper detected',
        ),
      ],
      accessRequests: [
        AccessRequestRecord(
          id: 'req_0001',
          request: AccessRequest(
            fullName: 'Jane Doe',
            email: 'jane@baitguard.com',
            company: 'BaitGuard',
            phone: '555-0101',
            department: 'Need admin access',
            submittedAt: now,
          ),
          status: AccessRequestStatus.pending,
        ),
        AccessRequestRecord(
          id: 'req_0002',
          request: AccessRequest(
            fullName: 'John Smith',
            email: 'john@baitguard.com',
            company: 'BaitGuard',
            phone: '555-0102',
            department: 'Technician role for Site 2',
            submittedAt: now,
          ),
          status: AccessRequestStatus.pending,
        ),
        AccessRequestRecord(
          id: 'req_0003',
          request: AccessRequest(
            fullName: 'Mike Johnson',
            email: 'mike@baitguard.com',
            company: 'BaitGuard',
            phone: '555-0103',
            department: 'Viewer access required',
            submittedAt: now.subtract(const Duration(days: 1)),
          ),
          status: AccessRequestStatus.pending,
        ),
      ],
      // Representative detection events for Screen 08 FeaturedStationCard.
      // These drive detection counts, recent species, and 7-day activity.
      // Dashboard-wide aggregates (120 stations, 42 detections today) are
      // kept separate in MockDeploymentSnapshot and are not updated by
      // individual station mutations.
      detectionEvents: [
        // RB-07 — Warehouse B (alert station, featured default)
        DetectionEvent(
          id: 'evt_rb07_1',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(hours: 2)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.96,
          alertId: 'alert_1',
        ),
        DetectionEvent(
          id: 'evt_rb07_2',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(days: 1, hours: 3)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.91,
        ),
        DetectionEvent(
          id: 'evt_rb07_3',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(days: 2, hours: 5)),
          species: DetectedSpecies.mouse,
          confidenceScore: 0.87,
        ),
        DetectionEvent(
          id: 'evt_rb07_4',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(days: 3, hours: 1)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.94,
        ),
        DetectionEvent(
          id: 'evt_rb07_5',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(days: 4, hours: 6)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.88,
        ),
        DetectionEvent(
          id: 'evt_rb07_6',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(days: 5, hours: 4)),
          species: DetectedSpecies.mouse,
          confidenceScore: 0.82,
        ),
        DetectionEvent(
          id: 'evt_rb07_7',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(days: 6, hours: 7)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.90,
        ),
        // Additional recent detections for total count
        DetectionEvent(
          id: 'evt_rb07_8',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(hours: 6)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.93,
        ),
        DetectionEvent(
          id: 'evt_rb07_9',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(hours: 10)),
          species: DetectedSpecies.mouse,
          confidenceScore: 0.85,
        ),
        DetectionEvent(
          id: 'evt_rb07_10',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(hours: 14)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.89,
        ),
        DetectionEvent(
          id: 'evt_rb07_11',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(hours: 18)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.92,
        ),
        DetectionEvent(
          id: 'evt_rb07_12',
          stationId: 'RB-07',
          timestamp: now.subtract(const Duration(hours: 22)),
          species: DetectedSpecies.mouse,
          confidenceScore: 0.80,
        ),
        // RB-01 — Kitchen area
        DetectionEvent(
          id: 'evt_rb01_1',
          stationId: 'RB-01',
          timestamp: now.subtract(const Duration(days: 1, hours: 2)),
          species: DetectedSpecies.mouse,
          confidenceScore: 0.88,
        ),
        DetectionEvent(
          id: 'evt_rb01_2',
          stationId: 'RB-01',
          timestamp: now.subtract(const Duration(days: 3, hours: 4)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.91,
        ),
        // RB-12 — Main entrance (tamper/alert)
        DetectionEvent(
          id: 'evt_rb12_1',
          stationId: 'RB-12',
          timestamp: now.subtract(const Duration(days: 1, hours: 1)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.95,
        ),
        DetectionEvent(
          id: 'evt_rb12_2',
          stationId: 'RB-12',
          timestamp: now.subtract(const Duration(days: 2, hours: 3)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.89,
        ),
        // RB-08 — Camera-less station with a mock event
        DetectionEvent(
          id: 'evt_rb08_1',
          stationId: 'RB-08',
          timestamp: now.subtract(const Duration(days: 5, hours: 8)),
          species: DetectedSpecies.rat,
          confidenceScore: 0.85,
          alertId: 'alert_7',
        ),
      ],
      reportExports: [
        ReportExport(
          id: 'export_mock_1',
          siteId: 'site_1',
          templateType: ReportTemplateType.complianceAudit,
          format: ReportFileFormat.pdf,
          title: 'Compliance Audit Report',
          fileName: 'Compliance_Audit_Q2.pdf',
          fileSizeBytes: 2400000,
          generatedAt: now.subtract(const Duration(days: 2)),
          period: ReportPeriod(type: ReportPeriodType.quarter, anchorDate: now),
        ),
        ReportExport(
          id: 'export_mock_2',
          siteId: 'site_1',
          templateType: ReportTemplateType.baitConsumption,
          format: ReportFileFormat.csv,
          title: 'Bait Consumption Report',
          fileName: 'Bait_Consumption_May.csv',
          fileSizeBytes: 84000,
          generatedAt: now.subtract(const Duration(days: 12)),
          period: ReportPeriod(
            type: ReportPeriodType.month,
            anchorDate: now.subtract(const Duration(days: 30)),
          ),
        ),
        ReportExport(
          id: 'export_mock_3',
          siteId: 'site_1',
          templateType: ReportTemplateType.monthlyActivity,
          format: ReportFileFormat.pdf,
          title: 'Monthly Activity Report',
          fileName: 'Monthly_Activity_Apr.pdf',
          fileSizeBytes: 1800000,
          generatedAt: now.subtract(const Duration(days: 42)),
          period: ReportPeriod(
            type: ReportPeriodType.month,
            anchorDate: now.subtract(const Duration(days: 60)),
          ),
        ),
      ],
    );
  }

  // Expose unmodifiable views
  List<Site> get sites => List.unmodifiable(_sites);
  List<AppUser> get users => List.unmodifiable(_users);
  List<Station> get stations => List.unmodifiable(_stations);
  List<Alert> get alerts => List.unmodifiable(_alerts);
  List<AccessRequestRecord> get accessRequests =>
      List.unmodifiable(_accessRequests);
  List<DetectionEvent> get detectionEvents =>
      List.unmodifiable(_detectionEvents);
  List<ReportExport> get reportExports => List.unmodifiable(_reportExports);

  // Settings
  UserSettings? getUserSettings(String userId) => _userSettings[userId];
  void updateUserSettings(UserSettings settings) {
    _userSettings[settings.userId] = settings;
  }

  // Users
  void updateUser(AppUser user) {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
  }

  /// Returns detection events for a specific station ID.
  List<DetectionEvent> getEventsForStation(String stationId) {
    return List.unmodifiable(
      _detectionEvents.where((e) => e.stationId == stationId).toList(),
    );
  }

  void addReportExport(ReportExport export) {
    _reportExports.add(export);
  }

  // Authentication matching
  AppUser? authenticate(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();

    // Explicit hardcoded password check for mock accounts
    String? expectedPassword;
    if (normalizedEmail == 'admin@baitguard.com') {
      expectedPassword = 'admin123';
    } else if (normalizedEmail == 'user@baitguard.com' ||
        normalizedEmail == 'inactive@baitguard.com') {
      expectedPassword = 'user123';
    } else if (normalizedEmail == 'technician@baitguard.com') {
      expectedPassword = 'tech123';
    }

    if (expectedPassword == null || password != expectedPassword) {
      return null;
    }

    try {
      return _users.firstWhere((u) => u.email.toLowerCase() == normalizedEmail);
    } catch (_) {
      return null;
    }
  }

  // Mutations

  void addAccessRequest(AccessRequest request) {
    final formattedNumber = _nextAccessRequestNumber.toString().padLeft(4, '0');
    _nextAccessRequestNumber++;

    final record = AccessRequestRecord(
      id: 'req_$formattedNumber',
      request: request,
      status: request.status,
    );
    _accessRequests.add(record);
  }

  void removeAccessRequest(String requestId) {
    _accessRequests.removeWhere((request) => request.id == requestId);
  }

  /// Mutates the shared station store to record a bait refill.
  ///
  /// Sets baitPercentage to 100, updates lastRefilledAt.
  /// Clears StationStatus.lowBait only when that was the sole condition.
  /// Preserves alert, tamper, and offline state.
  /// Throws [StateError] when [stationId] is not found.
  Station refillStation(String stationId) {
    final index = _stations.indexWhere((s) => s.id == stationId);
    if (index == -1) {
      throw StateError('Station not found: $stationId');
    }
    final old = _stations[index];

    // Only clear lowBait status when that is the sole condition.
    // Keep alert, offline, tamper combinations intact.
    StationStatus newStatus = old.status;
    if (old.status == StationStatus.lowBait) {
      newStatus = StationStatus.online;
    }

    final updated = old.copyWith(
      baitPercentage: 100.0,
      status: newStatus,
      lastRefilledAt: DateTime.now(),
    );
    _stations[index] = updated;
    return updated;
  }

  /// Mutates the shared station store to update notification-muted state.
  ///
  /// Does not alter StationStatus, alerts, or any other field.
  /// Throws [StateError] when [stationId] is not found.
  Station setStationNotificationsMuted(String stationId, bool muted) {
    final index = _stations.indexWhere((s) => s.id == stationId);
    if (index == -1) {
      throw StateError('Station $stationId not found.');
    }
    final updated = _stations[index].copyWith(notificationsMuted: muted);
    _stations[index] = updated;
    return updated;
  }

  Station registerStation(RegisterStationRequest request) {
    if (_stations.any(
      (s) => s.id.toLowerCase() == request.stationId.toLowerCase(),
    )) {
      throw StateError('Station with ID ${request.stationId} already exists.');
    }

    final newStation = Station(
      id: request.stationId,
      name: request.stationName,
      siteId: request.siteId,
      locationDescription: request.zoneLocation,
      status: StationStatus.online,
      baitPercentage: 100.0,
      batteryPercentage: 100.0,
      temperature: 22.0,
      humidity: 50.0,
      isTampered: false,
      lastSeen: DateTime.now(),
      hasCamera: true, // As requested in the prompt
      lastRefilledAt: DateTime.now(),
      notificationsMuted: false,
    );

    _stations.add(newStation);
    return newStation;
  }

  Alert updateAlert(Alert updatedAlert) {
    final index = _alerts.indexWhere((a) => a.id == updatedAlert.id);
    if (index == -1) {
      throw StateError('Alert not found: ${updatedAlert.id}');
    }
    _alerts[index] = updatedAlert;
    return updatedAlert;
  }
}
