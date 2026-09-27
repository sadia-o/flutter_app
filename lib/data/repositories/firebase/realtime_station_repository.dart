import '../../../domain/models/detection_event.dart';
import '../../../domain/models/register_station_request.dart';
import '../../../domain/models/station.dart';
import '../../../domain/repositories/station_repository.dart';
import 'realtime_station_data_source.dart';

class RealtimeStationRepository implements StationRepository {
  final RealtimeStationDataSource _dataSource;

  RealtimeStationRepository(this._dataSource);

  @override
  bool get supportsMutations => false;

  @override
  Future<List<Station>> getStations({String? siteId}) async {
    if (siteId != null &&
        siteId != RealtimeStationDataSource.kPilotFacilityId) {
      // Facility isolation: pilot station_01 only belongs to site_1
      return const [];
    }

    final station = await _dataSource.fetchStation(
      RealtimeStationDataSource.kPilotStationId,
      forceRefresh: true,
    );
    if (station != null) {
      return [station];
    }
    return const [];
  }

  @override
  Future<Station?> getStationById(String id) async {
    if (id != RealtimeStationDataSource.kPilotStationId) return null;
    return _dataSource.fetchStation(id, forceRefresh: true);
  }

  @override
  Future<List<DetectionEvent>> getStationEvents(String stationId) async {
    if (stationId != RealtimeStationDataSource.kPilotStationId) {
      return const [];
    }
    return _dataSource.fetchStationEvents(stationId, forceRefresh: true);
  }

  @override
  Stream<List<Station>> watchStations({String? siteId}) async* {
    if (siteId != null &&
        siteId != RealtimeStationDataSource.kPilotFacilityId) {
      yield const [];
      return;
    }

    // Emit current state immediately if available
    final current = _dataSource.currentStation;
    if (current != null) {
      yield [current];
    }

    // Stream subsequent updates
    yield* _dataSource.stationStream.map(
      (s) => s != null ? [s] : const <Station>[],
    );
  }

  @override
  Stream<Station?> watchStationById(String id) async* {
    if (id != RealtimeStationDataSource.kPilotStationId) {
      yield null;
      return;
    }

    final current = _dataSource.currentStation;
    if (current != null) {
      yield current;
    }

    yield* _dataSource.stationStream.where((s) => s == null || s.id == id);
  }

  @override
  Stream<List<DetectionEvent>> watchStationEvents(String stationId) async* {
    if (stationId != RealtimeStationDataSource.kPilotStationId) {
      yield const [];
      return;
    }

    if (_dataSource.currentEvents.isNotEmpty) {
      yield _dataSource.currentEvents;
    }

    yield* _dataSource.eventsStream;
  }

  @override
  Future<Station> recordRefill(String stationId) {
    throw UnsupportedError(
      'Telemetry writes are reserved for hardware stations in this pilot.',
    );
  }

  @override
  Future<Station> setNotificationsMuted({
    required String stationId,
    required bool muted,
  }) {
    throw UnsupportedError(
      'Notification mute writes are unsupported for hardware stations in this pilot.',
    );
  }

  @override
  Future<Station> registerStation(RegisterStationRequest request) {
    throw UnsupportedError(
      'Station registration is operator-managed in this pilot.',
    );
  }
}
