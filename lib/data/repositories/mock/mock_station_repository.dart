import '../../../domain/models/station.dart';
import '../../../domain/models/detection_event.dart';
import '../../../domain/models/register_station_request.dart';
import '../../../domain/repositories/station_repository.dart';
import 'mock_baitguard_data_source.dart';

export '../../../domain/models/station.dart'
    show
        kLowBaitThreshold,
        stationIsLowBait,
        stationNeedsAttention,
        stationIsConnected;

class MockStationRepository implements StationRepository {
  final MockBaitGuardDataSource _dataSource;

  MockStationRepository(this._dataSource);

  @override
  Future<List<Station>> getStations({String? siteId}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    var stations = _dataSource.stations;
    if (siteId != null) {
      stations = stations.where((s) => s.siteId == siteId).toList();
    }
    return stations;
  }

  @override
  Future<Station?> getStationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final stations = _dataSource.stations;
    try {
      return stations.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DetectionEvent>> getStationEvents(String stationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _dataSource.getEventsForStation(stationId);
  }

  @override
  Future<Station> recordRefill(String stationId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _dataSource.refillStation(stationId);
  }

  @override
  Future<Station> setNotificationsMuted({
    required String stationId,
    required bool muted,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _dataSource.setStationNotificationsMuted(stationId, muted);
  }

  @override
  Future<Station> registerStation(RegisterStationRequest request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _dataSource.registerStation(request);
  }

  @override
  bool get supportsMutations => true;

  @override
  Stream<List<Station>> watchStations({String? siteId}) async* {
    var stations = _dataSource.stations;
    if (siteId != null) {
      stations = stations.where((s) => s.siteId == siteId).toList();
    }
    yield List.unmodifiable(stations);
  }

  @override
  Stream<Station?> watchStationById(String id) async* {
    final stations = _dataSource.stations;
    try {
      yield stations.firstWhere((s) => s.id == id);
    } catch (_) {
      yield null;
    }
  }

  @override
  Stream<List<DetectionEvent>> watchStationEvents(String stationId) async* {
    yield List.unmodifiable(_dataSource.getEventsForStation(stationId));
  }
}
