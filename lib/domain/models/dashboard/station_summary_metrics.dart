class StationSummaryMetrics {
  final int totalCount;
  final int activeCount;
  final int offlineCount;
  final int refillNeededCount;

  const StationSummaryMetrics({
    required this.totalCount,
    required this.activeCount,
    required this.offlineCount,
    required this.refillNeededCount,
  });
}
