import '../station_status.dart';

class StationMapMarker {
  final String stationId;
  final String name;
  final double normalizedX;
  final double normalizedY;
  final StationStatus status;

  const StationMapMarker({
    required this.stationId,
    required this.name,
    required this.normalizedX,
    required this.normalizedY,
    required this.status,
  });
}
