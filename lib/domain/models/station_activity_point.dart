/// A single data point for a station's detection activity over time.
/// Used in the seven-day activity sparkline on the Featured Station Card.
class StationActivityPoint {
  final DateTime timestamp;
  final int detections;

  const StationActivityPoint({
    required this.timestamp,
    required this.detections,
  });
}
