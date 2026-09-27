import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/alert.dart';
import '../../../domain/models/alert_severity.dart';
import '../../../domain/models/alert_status.dart';
import '../../../domain/models/alert_type.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/detected_species.dart';
import '../../../domain/models/detection_event.dart';
import '../../../domain/models/station.dart';
import '../../../domain/models/station_status.dart';

/// Central reactive data source connecting to Firebase Realtime Database
/// for hardware station telemetry and detection events.
///
/// Pilot Configuration:
/// - Station ID: 'station_01'
/// - Facility ID: 'site_1'
/// - RTDB URL: https://bait-guard-6f470-default-rtdb.firebaseio.com/
class RealtimeStationDataSource {
  static const String kDefaultDatabaseUrl =
      'https://bait-guard-6f470-default-rtdb.firebaseio.com/';
  static const String kPilotStationId = 'station_01';
  static const String kPilotFacilityId = 'site_1';
  static const double kLowBaitThreshold = 25.0;

  final FirebaseDatabase? _database;
  final Duration stalenessThreshold;
  final DateTime Function() _clock;

  // Active subscriptions & timers
  StreamSubscription<DatabaseEvent>? _liveSubscription;
  StreamSubscription<DatabaseEvent>? _eventsSubscription;
  Timer? _freshnessTimer;

  // Session and facility isolation tracking
  int _sessionToken = 0;
  String? _currentUserId;
  bool _isActive = false;
  String? _activeFacilityId;
  bool _isPermitted = false;
  bool _isListening = false;

  // Cached state
  Station? _cachedStation;
  List<DetectionEvent> _cachedEvents = const [];
  List<Alert> _cachedAlerts = const [];

  // Stream broadcast controllers
  final _stationController = StreamController<Station?>.broadcast();
  final _eventsController = StreamController<List<DetectionEvent>>.broadcast();
  final _alertsController = StreamController<List<Alert>>.broadcast();

  RealtimeStationDataSource({
    FirebaseDatabase? database,
    this.stalenessThreshold = const Duration(minutes: 30),
    DateTime Function()? clock,
  }) : _database =
           database ??
           (Firebase.apps.isNotEmpty
               ? FirebaseDatabase.instanceFor(
                   app: Firebase.app(),
                   databaseURL: kDefaultDatabaseUrl,
                 )
               : null),
       _clock = clock ?? DateTime.now;

  Station? get currentStation => _cachedStation;
  List<DetectionEvent> get currentEvents => _cachedEvents;
  List<Alert> get currentAlerts => _cachedAlerts;

  Stream<Station?> get stationStream => _stationController.stream;
  Stream<List<DetectionEvent>> get eventsStream => _eventsController.stream;
  Stream<List<Alert>> get alertsStream => _alertsController.stream;

  String? get activeFacilityId => _activeFacilityId;
  bool get isListening => _isListening;
  int get sessionToken => _sessionToken;

  /// Binds the data source to the current authenticated user and selected facility.
  ///
  /// Enforces:
  /// - Only active users with granted facility access to 'site_1' can start listeners.
  /// - If user is null, inactive, has no facility permissions, or switches to an
  ///   unauthorized facility, all listeners and caches are immediately cleared.
  /// - Advances session token so obsolete in-flight async operations are discarded.
  void bindSessionAndFacility({
    required AppUser? user,
    required String? facilityId,
  }) {
    final hasActiveUser = user != null && user.isActive;
    final isPermittedForFacility =
        hasActiveUser &&
        facilityId != null &&
        user.siteAccessIds.contains(facilityId);

    // If context is completely unchanged, do nothing
    if (_currentUserId == user?.id &&
        _isActive == hasActiveUser &&
        _activeFacilityId == facilityId &&
        _isPermitted == isPermittedForFacility &&
        _isListening) {
      return;
    }

    _sessionToken++;
    _currentUserId = user?.id;
    _isActive = hasActiveUser;
    _activeFacilityId = facilityId;
    _isPermitted = isPermittedForFacility;

    if (hasActiveUser &&
        isPermittedForFacility &&
        facilityId == kPilotFacilityId) {
      _startListening();
    } else {
      _stopListeningAndClear();
    }
  }

  /// Backward-compatible helper that delegates to [bindSessionAndFacility].
  void setFacilityContext(String? facilityId, {required bool isPermitted}) {
    if (_activeFacilityId == facilityId &&
        _isPermitted == isPermitted &&
        _isListening) {
      return;
    }

    _sessionToken++;
    _activeFacilityId = facilityId;
    _isPermitted = isPermitted;

    if (facilityId == kPilotFacilityId && isPermitted) {
      _startListening();
    } else {
      _stopListeningAndClear();
    }
  }

  void _startListening() {
    _stopSubscriptions();
    _isListening = true;

    // Start background staleness check timer
    _freshnessTimer?.cancel();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkFreshness();
    });

    final db = _database;
    if (db == null) return;

    final token = _sessionToken;

    try {
      final liveRef = db.ref('stationLive/$kPilotStationId');
      _liveSubscription = liveRef.onValue.listen(
        (event) {
          if (_sessionToken != token) return;
          final raw = event.snapshot.value;
          final parsed = parseStationLive(
            raw,
            stalenessThreshold: stalenessThreshold,
            clock: _clock,
          );
          _cachedStation = parsed;
          // Re-evaluate alerts with live station context (e.g. bait level)
          if (_cachedAlerts.isNotEmpty) {
            _cachedAlerts = _adjustAlertsWithLiveState(_cachedAlerts, parsed);
            _alertsController.add(_cachedAlerts);
          }
          _stationController.add(_cachedStation);
        },
        onError: (error) {
          if (_sessionToken != token) return;
          if (kDebugMode) {
            debugPrint('RealtimeStationDataSource stationLive error: $error');
          }
          _stationController.addError(error);
        },
      );

      final eventsRef = db.ref('stationEvents/$kPilotStationId');
      _eventsSubscription = eventsRef.onValue.listen(
        (event) {
          if (_sessionToken != token) return;
          final raw = event.snapshot.value;
          final parsed = parseStationEventsMap(raw);
          _cachedEvents = parsed.events;
          _cachedAlerts = _adjustAlertsWithLiveState(
            parsed.alerts,
            _cachedStation,
          );

          _eventsController.add(_cachedEvents);
          _alertsController.add(_cachedAlerts);
        },
        onError: (error) {
          if (_sessionToken != token) return;
          if (kDebugMode) {
            debugPrint('RealtimeStationDataSource stationEvents error: $error');
          }
          _eventsController.addError(error);
          _alertsController.addError(error);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to attach RTDB listeners: $e');
      }
    }
  }

  void _stopSubscriptions() {
    _liveSubscription?.cancel();
    _liveSubscription = null;
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
    _freshnessTimer?.cancel();
    _freshnessTimer = null;
    _isListening = false;
  }

  void _stopListeningAndClear() {
    _stopSubscriptions();
    _cachedStation = null;
    _cachedEvents = const [];
    _cachedAlerts = const [];

    _stationController.add(null);
    _eventsController.add(const []);
    _alertsController.add(const []);
  }

  /// Checks if the cached station has exceeded [stalenessThreshold].
  ///
  /// A previously online station becomes offline after the 30-minute heartbeat
  /// timeout even when Firebase sends no further update.
  void checkFreshness() {
    final st = _cachedStation;
    if (st == null) return;
    if (st.status == StationStatus.offline) return;

    final now = _clock().toUtc();
    final lastSeenUtc = st.lastSeen.toUtc();
    if (now.difference(lastSeenUtc) > stalenessThreshold) {
      _cachedStation = st.copyWith(status: StationStatus.offline);
      _stationController.add(_cachedStation);
    }
  }

  /// One-off read for station_01 telemetry.
  ///
  /// If [forceRefresh] is false and cache exists, returns cached data.
  /// Discards responses if the session token changed while in flight.
  Future<Station?> fetchStation(
    String stationId, {
    bool forceRefresh = false,
  }) async {
    if (stationId != kPilotStationId) return null;
    if (!forceRefresh && _cachedStation != null) return _cachedStation;

    final db = _database;
    if (db == null) return _cachedStation;

    final token = _sessionToken;

    try {
      final snapshot = await db.ref('stationLive/$kPilotStationId').get();
      if (_sessionToken != token) return null; // Context changed while fetching

      final station = parseStationLive(
        snapshot.value,
        stalenessThreshold: stalenessThreshold,
        clock: _clock,
      );
      if (station != null) {
        _cachedStation = station;
        _stationController.add(station);
      }
      return station;
    } catch (e) {
      if (_sessionToken != token) return null;
      if (kDebugMode) {
        debugPrint('fetchStation failed: $e');
      }
      rethrow;
    }
  }

  /// One-off read for station events.
  Future<List<DetectionEvent>> fetchStationEvents(
    String stationId, {
    bool forceRefresh = false,
  }) async {
    if (stationId != kPilotStationId) return const [];
    if (!forceRefresh && _cachedEvents.isNotEmpty) return _cachedEvents;

    final db = _database;
    if (db == null) return _cachedEvents;

    final token = _sessionToken;

    try {
      final snapshot = await db.ref('stationEvents/$kPilotStationId').get();
      if (_sessionToken != token) return const [];

      final parsed = parseStationEventsMap(snapshot.value);
      _cachedEvents = parsed.events;
      _cachedAlerts = _adjustAlertsWithLiveState(parsed.alerts, _cachedStation);

      _eventsController.add(_cachedEvents);
      _alertsController.add(_cachedAlerts);
      return _cachedEvents;
    } catch (e) {
      if (_sessionToken != token) return const [];
      if (kDebugMode) {
        debugPrint('fetchStationEvents failed: $e');
      }
      rethrow;
    }
  }

  /// One-off read for alerts derived from events.
  Future<List<Alert>> fetchAlerts({
    required String siteId,
    bool forceRefresh = false,
  }) async {
    if (siteId != kPilotFacilityId) return const [];
    if (!forceRefresh && _cachedAlerts.isNotEmpty) return _cachedAlerts;

    final db = _database;
    if (db == null) return _cachedAlerts;

    final token = _sessionToken;

    try {
      final snapshot = await db.ref('stationEvents/$kPilotStationId').get();
      if (_sessionToken != token) return const [];

      final parsed = parseStationEventsMap(snapshot.value);
      _cachedEvents = parsed.events;
      _cachedAlerts = _adjustAlertsWithLiveState(parsed.alerts, _cachedStation);

      _eventsController.add(_cachedEvents);
      _alertsController.add(_cachedAlerts);
      return _cachedAlerts;
    } catch (e) {
      if (_sessionToken != token) return const [];
      if (kDebugMode) {
        debugPrint('fetchAlerts failed: $e');
      }
      rethrow;
    }
  }

  /// Feeds simulated live telemetry directly for testing and reactive updates.
  @visibleForTesting
  void updateFromLivePayload(dynamic raw) {
    _cachedStation = parseStationLive(
      raw,
      stalenessThreshold: stalenessThreshold,
      clock: _clock,
    );
    if (_cachedAlerts.isNotEmpty) {
      _cachedAlerts = _adjustAlertsWithLiveState(_cachedAlerts, _cachedStation);
      _alertsController.add(_cachedAlerts);
    }
    _stationController.add(_cachedStation);
  }

  /// Feeds simulated station events directly for testing and reactive updates.
  @visibleForTesting
  void updateFromEventsPayload(dynamic raw) {
    final parsed = parseStationEventsMap(raw);
    _cachedEvents = parsed.events;
    _cachedAlerts = _adjustAlertsWithLiveState(parsed.alerts, _cachedStation);
    _eventsController.add(_cachedEvents);
    _alertsController.add(_cachedAlerts);
  }

  @visibleForTesting
  Station? get cachedStation => _cachedStation;

  @visibleForTesting
  List<DetectionEvent> get cachedEvents => _cachedEvents;

  // ---------------------------------------------------------------------------
  // Static Parsing Helpers
  // ---------------------------------------------------------------------------

  /// Parses live station telemetry.
  ///
  /// Strictly requires:
  /// - `device_id` == 'station_01'
  /// - `facility_id` == 'site_1'
  /// - `battery_percentage` number in range [0, 100]
  /// - `bait_percentage` number in range [0, 100]
  /// - `online` boolean
  /// - `last_seen_at` number > 0
  ///
  /// Returns null if any required field is missing, invalid, or out of range.
  static Station? parseStationLive(
    dynamic data, {
    Duration stalenessThreshold = const Duration(minutes: 30),
    DateTime Function()? clock,
  }) {
    if (data == null || data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    final deviceId = map['device_id'];
    final facilityId = map['facility_id'];
    final batteryRaw = map['battery_percentage'];
    final baitRaw = map['bait_percentage'];
    final onlineRaw = map['online'];
    final lastSeenRaw = map['last_seen_at'];

    // Reject mismatched identity
    if (deviceId != kPilotStationId || facilityId != kPilotFacilityId) {
      return null;
    }

    // Validate types and ranges
    if (batteryRaw is! num || batteryRaw < 0 || batteryRaw > 100) return null;
    if (baitRaw is! num || baitRaw < 0 || baitRaw > 100) return null;
    if (onlineRaw is! bool) return null;
    if (lastSeenRaw is! num || lastSeenRaw <= 0) return null;

    final battery = batteryRaw.toDouble();
    final bait = baitRaw.toDouble();
    final isOnline = onlineRaw;
    final lastSeenMillis = lastSeenRaw.toInt();

    final lastSeenUtc = DateTime.fromMillisecondsSinceEpoch(
      lastSeenMillis,
      isUtc: true,
    );
    final lastSeen = lastSeenUtc.toLocal();

    final now = (clock?.call() ?? DateTime.now()).toUtc();
    final isStale = now.difference(lastSeenUtc) > stalenessThreshold;

    StationStatus status;
    if (!isOnline || isStale) {
      status = StationStatus.offline;
    } else if (bait <= kLowBaitThreshold) {
      status = StationStatus.lowBait;
    } else {
      status = StationStatus.online;
    }

    return Station(
      id: kPilotStationId,
      name: 'Pilot Station 01',
      siteId: kPilotFacilityId,
      locationDescription: 'Warehouse A · Main Zone',
      status: status,
      baitPercentage: bait,
      batteryPercentage: battery,
      temperature: null, // Unsupported by RTDB schema
      humidity: null, // Unsupported by RTDB schema
      isTampered: false,
      hasTamperData:
          false, // Unsupported by RTDB schema: missing tamper data must not imply confirmed not tampered
      lastSeen: lastSeen,
      hasCamera: true, // Static camera placeholder available
      notificationsMuted: false,
    );
  }

  /// Parses station events map.
  ///
  /// Strictly requires:
  /// - `device_id` == 'station_01'
  /// - `facility_id` == 'site_1'
  /// - `event_type` == 'rat_detected' or 'low_bait_alert'
  /// - `timestamp` number > 0
  ///
  /// For `rat_detected`:
  /// - Must NOT contain low-bait fields (`current_pixels`, `bait_percentage`, `status`).
  /// - Produces a rodent DetectionEvent and an Alert.
  ///
  /// For `low_bait_alert`:
  /// - Must contain `current_pixels` (number >= 0), `bait_percentage` (number 0..100),
  ///   and `status` ('Normal', 'Low', 'Refill Required').
  /// - Produces an Alert only (NOT a rodent DetectionEvent).
  static ({List<DetectionEvent> events, List<Alert> alerts})
  parseStationEventsMap(dynamic data) {
    if (data == null || data is! Map) {
      return (events: const <DetectionEvent>[], alerts: const <Alert>[]);
    }

    final rawMap = Map<String, dynamic>.from(data);
    final eventsList = <DetectionEvent>[];
    final alertsList = <Alert>[];

    final sortedEntries = rawMap.entries.toList()
      ..sort((a, b) {
        final aVal = a.value is Map ? (a.value['timestamp'] as num?) ?? 0 : 0;
        final bVal = b.value is Map ? (b.value['timestamp'] as num?) ?? 0 : 0;
        return bVal.compareTo(aVal); // Newest first
      });

    for (final entry in sortedEntries) {
      final key = entry.key;
      final val = entry.value;
      if (val is! Map) continue;
      final map = Map<String, dynamic>.from(val);

      final deviceId = map['device_id'];
      final facilityId = map['facility_id'];
      final eventType = map['event_type'];
      final tsRaw = map['timestamp'];

      // Reject mismatched identity or missing basic fields
      if (deviceId != kPilotStationId || facilityId != kPilotFacilityId) {
        continue;
      }
      if (tsRaw is! num || tsRaw <= 0) continue;

      final ts = DateTime.fromMillisecondsSinceEpoch(
        tsRaw.toInt(),
        isUtc: true,
      ).toLocal();

      if (eventType == 'rat_detected') {
        // Must reject if any low-bait-only field is present
        if (map.containsKey('bait_percentage') ||
            map.containsKey('current_pixels') ||
            map.containsKey('status')) {
          continue;
        }

        final alertId = 'alert_$key';
        eventsList.add(
          DetectionEvent(
            id: key,
            stationId: kPilotStationId,
            timestamp: ts,
            species: DetectedSpecies.rat,
            confidenceScore: null, // Unavailable in hardware schema
            evidenceImageUrl: null,
            status: DetectionEventStatus.open,
            alertId: alertId,
          ),
        );

        alertsList.add(
          Alert(
            id: alertId,
            stationId: kPilotStationId,
            type: AlertType.rodent,
            severity: AlertSeverity.critical,
            status: AlertStatus.open,
            timestamp: ts,
            description: 'Rat detected at $kPilotStationId',
            detectionEventId: key,
            isRead: false,
          ),
        );
      } else if (eventType == 'low_bait_alert') {
        // Must require current_pixels, bait_percentage, and status
        final baitPctRaw = map['bait_percentage'];
        final currentPixels = map['current_pixels'];
        final statusStr = map['status'];

        if (baitPctRaw is! num || baitPctRaw < 0 || baitPctRaw > 100) continue;
        if (currentPixels is! num || currentPixels < 0) continue;
        if (statusStr is! String ||
            (statusStr != 'Normal' &&
                statusStr != 'Low' &&
                statusStr != 'Refill Required')) {
          continue;
        }

        final baitPct = baitPctRaw.toInt();
        final desc = 'Low bait level ($baitPct%) — $statusStr';

        alertsList.add(
          Alert(
            id: 'alert_$key',
            stationId: kPilotStationId,
            type: AlertType.lowBait,
            severity: AlertSeverity.warning,
            status: AlertStatus.open,
            timestamp: ts,
            description: desc,
            detectionEventId: null,
            isRead: false,
          ),
        );
      }
    }

    return (
      events: List.unmodifiable(eventsList),
      alerts: List.unmodifiable(alertsList),
    );
  }

  /// Ensures historical low-bait alerts do not override a newer healthy live bait reading.
  static List<Alert> _adjustAlertsWithLiveState(
    List<Alert> alerts,
    Station? liveStation,
  ) {
    if (liveStation == null) return alerts;

    final isLiveBaitHealthy = liveStation.baitPercentage > kLowBaitThreshold;
    if (!isLiveBaitHealthy) return alerts;

    // When live bait is healthy (>25%), historical low bait alerts should not be active open alerts
    return alerts.map((a) {
      if (a.type == AlertType.lowBait && a.status == AlertStatus.open) {
        return a.copyWith(status: AlertStatus.resolved);
      }
      return a;
    }).toList();
  }

  void dispose() {
    _stopSubscriptions();
    _stationController.close();
    _eventsController.close();
    _alertsController.close();
  }
}
