import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/detected_species.dart';
import '../../../domain/models/detection_event.dart';
import '../../../domain/models/station.dart';
import '../../../domain/models/station_activity_point.dart';
import '../../../domain/models/station_overview_data.dart';
import '../../../domain/models/station_status.dart';
import '../../../domain/repositories/station_repository.dart';
import '../models/station_list_filter.dart';
import '../models/station_permissions.dart';

enum StationsLoadStatus { initial, loading, success, failure }

class StationsViewModel extends ChangeNotifier {
  final StationRepository _stationRepository;
  final AppSessionController _sessionController;
  final ActiveFacilityController _facilityController;

  StationsLoadStatus _status = StationsLoadStatus.initial;
  StationsLoadStatus get status => _status;

  List<Station> _allStations = const [];
  List<Station> get allStations => _allStations;

  List<Station> _filteredStations = const [];
  List<Station> get filteredStations => _filteredStations;

  StationOverviewData? _featuredStation;
  StationOverviewData? get featuredStation => _featuredStation;

  StationListFilter _selectedFilter = StationListFilter.all;
  StationListFilter get selectedFilter => _selectedFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  StationPermissions _permissions = StationPermissions.readOnly;
  StationPermissions get permissions => _permissions;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // One-time refresh error event
  int _refreshErrorEventId = 0;
  int get refreshErrorEventId => _refreshErrorEventId;
  String? _refreshErrorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;

  // One-time action result events (success or failure after refill/silence)
  int _actionEventId = 0;
  int get actionEventId => _actionEventId;
  String? _actionMessage;
  String? get actionMessage => _actionMessage;

  bool _isLoading = false;
  StreamSubscription<List<Station>>? _stationsSubscription;

  /// Station IDs with a mutation currently in progress.
  final Set<String> _mutatingStationIds = {};

  bool isMutating(String stationId) => _mutatingStationIds.contains(stationId);

  // Cached event data, loaded once per session per station.
  final Map<String, List<DetectionEvent>> _eventCache = {};

  // Track the last site we loaded to avoid redundant reloads.
  String? _lastLoadedSiteId;

  StationsViewModel({
    required StationRepository stationRepository,
    required AppSessionController sessionController,
    required ActiveFacilityController activeFacilityController,
  }) : _stationRepository = stationRepository,
       _sessionController = sessionController,
       _facilityController = activeFacilityController {
    _facilityController.addListener(_onFacilityChanged);
  }

  bool _disposed = false;

  void _onFacilityChanged() {
    if (_disposed) return;
    final newSiteId = _facilityController.selectedSiteId;
    if (newSiteId == null) return;
    if (newSiteId == _lastLoadedSiteId) return; // No-op on same site
    _stationsSubscription?.cancel();
    _stationsSubscription = null;
    _eventCache.clear();
    load();
  }

  Future<void> load() async {
    if (_disposed || _isLoading) return;

    final user = _sessionController.currentUser;
    if (user == null) {
      _status = StationsLoadStatus.failure;
      _errorMessage = 'No active session. Please sign in again.';
      if (!_disposed) notifyListeners();
      return;
    }

    final siteId = _facilityController.selectedSiteId;
    if (siteId == null) {
      _status = StationsLoadStatus.failure;
      _errorMessage = 'No permitted facility available.';
      if (!_disposed) notifyListeners();
      return;
    }

    _isLoading = true;
    _status = StationsLoadStatus.loading;
    _errorMessage = null;
    if (!_disposed) notifyListeners();

    await _fetchStations(siteId: siteId, isRefresh: false);
  }

  Future<void> refresh() async {
    if (_disposed || _isLoading) return;

    final siteId = _facilityController.selectedSiteId;
    if (siteId == null) return;

    _isLoading = true;
    // Keep status as-is so existing data stays visible.
    if (!_disposed) notifyListeners();

    await _fetchStations(siteId: siteId, isRefresh: true);
  }

  Future<void> _fetchStations({
    required String siteId,
    required bool isRefresh,
  }) async {
    try {
      final user = _sessionController.currentUser;
      if (user == null) throw StateError('No active session');

      _permissions = StationPermissions.fromRole(
        user.role,
        supportsMutations: _stationRepository.supportsMutations,
      );

      final stations = await _stationRepository.getStations(siteId: siteId);

      if (isRefresh) {
        _eventCache.clear();
      }

      for (final station in stations) {
        if (!_eventCache.containsKey(station.id)) {
          try {
            final events = await _stationRepository.getStationEvents(
              station.id,
            );
            _eventCache[station.id] = events;
          } catch (_) {}
        }
      }

      if (_disposed) return;

      _allStations = List.unmodifiable(stations);
      _lastLoadedSiteId = siteId;
      _status = StationsLoadStatus.success;
      _errorMessage = null;

      _applyFilterAndSearch();

      if (!isRefresh) {
        _stationsSubscription?.cancel();
        _stationsSubscription = _stationRepository
            .watchStations(siteId: siteId)
            .listen(
              (updatedStations) async {
                if (_disposed) return;
                for (final station in updatedStations) {
                  if (!_eventCache.containsKey(station.id)) {
                    try {
                      final events = await _stationRepository.getStationEvents(
                        station.id,
                      );
                      _eventCache[station.id] = events;
                    } catch (_) {}
                  }
                }
                _allStations = List.unmodifiable(updatedStations);
                _lastLoadedSiteId = siteId;
                _status = StationsLoadStatus.success;
                _errorMessage = null;
                _applyFilterAndSearch();
                notifyListeners();
              },
              onError: (e) {
                if (_disposed) return;
                if (_allStations.isEmpty) {
                  _status = StationsLoadStatus.failure;
                  _errorMessage = 'Could not load stations. Please try again.';
                  notifyListeners();
                }
              },
            );
      }
    } catch (e) {
      if (_disposed) return;
      if (isRefresh && _allStations.isNotEmpty) {
        _refreshErrorMessage = 'Failed to refresh stations. Please try again.';
        _refreshErrorEventId++;
      } else {
        _status = StationsLoadStatus.failure;
        _errorMessage = 'Could not load stations. Please try again.';
      }
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void setFilter(StationListFilter filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    _applyFilterAndSearch();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _applyFilterAndSearch();
    notifyListeners();
  }

  void clearSearchAndFilter() {
    _searchQuery = '';
    _selectedFilter = StationListFilter.all;
    _applyFilterAndSearch();
    notifyListeners();
  }

  void _applyFilterAndSearch() {
    var result = _allStations.toList();

    // Apply filter
    switch (_selectedFilter) {
      case StationListFilter.all:
        break;
      case StationListFilter.alerts:
        result = result.where(stationNeedsAttention).toList();
        break;
      case StationListFilter.lowBait:
        result = result.where(stationIsLowBait).toList();
        break;
      case StationListFilter.online:
        result = result.where(stationIsConnected).toList();
        break;
    }

    // Apply search
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((s) {
        return s.id.toLowerCase().contains(q) ||
            s.locationDescription.toLowerCase().contains(q) ||
            s.name.toLowerCase().contains(q);
      }).toList();
    }

    _filteredStations = List.unmodifiable(result);
    _updateFeaturedStation();
  }

  void _updateFeaturedStation() {
    if (_filteredStations.isEmpty) {
      _featuredStation = null;
      return;
    }

    // Preserve current featured station when it still exists in results.
    final currentId = _featuredStation?.station.id;
    if (currentId != null) {
      final stillPresent = _filteredStations.any((s) => s.id == currentId);
      if (stillPresent) {
        // Update with fresh data from allStations (e.g. after refill/silence).
        final refreshed = _allStations.firstWhere(
          (s) => s.id == currentId,
          orElse: () => _filteredStations.first,
        );
        _featuredStation = _buildOverview(refreshed);
        return;
      }
    }

    // Priority: alert/tampered → offline → lowBait → online
    Station? pick;

    pick = _filteredStations.firstWhereOrNull(
      (s) => s.status == StationStatus.alert || s.isTampered,
    );
    pick ??= _filteredStations.firstWhereOrNull(
      (s) => s.status == StationStatus.offline,
    );
    pick ??= _filteredStations.firstWhereOrNull(stationIsLowBait);
    pick ??= _filteredStations.first;

    _featuredStation = _buildOverview(pick);
  }

  StationOverviewData _buildOverview(Station station) {
    final events = _eventCache[station.id] ?? const [];

    // Build 7-day daily activity (oldest → newest).
    final now = DateTime.now();
    final sevenDayActivity = <StationActivityPoint>[];
    for (int i = 6; i >= 0; i--) {
      final dayStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final count = events
          .where(
            (e) =>
                e.timestamp.isAfter(dayStart) && e.timestamp.isBefore(dayEnd),
          )
          .length;
      sevenDayActivity.add(
        StationActivityPoint(timestamp: dayStart, detections: count),
      );
    }

    // Most recent detection for species/confidence badge.
    DetectedSpecies? recentSpecies;
    double? recentConfidence;
    if (events.isNotEmpty) {
      final sorted = events.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latest = sorted.first;
      if (latest.species != DetectedSpecies.none) {
        recentSpecies = latest.species;
        recentConfidence = latest.confidenceScore;
      }
    }

    return StationOverviewData(
      station: station,
      detectionCount: events.length,
      sevenDayActivity: sevenDayActivity,
      recentSpecies: recentSpecies,
      recentConfidence: recentConfidence,
    );
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> refillStation(String stationId) async {
    if (!_permissions.canRefill) return;
    if (_mutatingStationIds.contains(stationId)) return;

    _mutatingStationIds.add(stationId);
    notifyListeners();

    try {
      final updated = await _stationRepository.recordRefill(stationId);
      _updateLocalStation(updated);
      _actionMessage = '$stationId marked as refilled.';
      _actionEventId++;
    } catch (_) {
      _actionMessage = 'Failed to record refill for $stationId.';
      _actionEventId++;
    } finally {
      _mutatingStationIds.remove(stationId);
      notifyListeners();
    }
  }

  Future<void> toggleSilenceStation(String stationId) async {
    if (!_permissions.canSilence) return;
    if (_mutatingStationIds.contains(stationId)) return;

    final current = _allStations.firstWhereOrNull((s) => s.id == stationId);
    if (current == null) return;

    final newMuted = !current.notificationsMuted;

    _mutatingStationIds.add(stationId);
    notifyListeners();

    try {
      final updated = await _stationRepository.setNotificationsMuted(
        stationId: stationId,
        muted: newMuted,
      );
      _updateLocalStation(updated);
      _actionMessage = newMuted
          ? '$stationId notifications silenced.'
          : '$stationId notifications unsilenced.';
      _actionEventId++;
    } catch (_) {
      _actionMessage = 'Failed to update notifications for $stationId.';
      _actionEventId++;
    } finally {
      _mutatingStationIds.remove(stationId);
      notifyListeners();
    }
  }

  void _updateLocalStation(Station updated) {
    final idx = _allStations.indexWhere((s) => s.id == updated.id);
    if (idx == -1) return;
    final mutable = _allStations.toList();
    mutable[idx] = updated;
    _allStations = List.unmodifiable(mutable);
    _applyFilterAndSearch();
  }

  // ---------------------------------------------------------------------------
  // Derived counts
  // ---------------------------------------------------------------------------

  /// Total stations in the currently loaded facility.
  int get totalCount => _allStations.length;

  /// Active (connected) stations in the currently loaded facility.
  int get activeCount => _allStations.where(stationIsConnected).length;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _disposed = true;
    _stationsSubscription?.cancel();
    _stationsSubscription = null;
    _facilityController.removeListener(_onFacilityChanged);
    super.dispose();
  }
}

extension _ListExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
