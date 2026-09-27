class DashboardSummary {
  final int totalStations;
  final int onlineStations;
  final int offlineStations;
  final int totalAlerts;
  final int criticalAlerts;
  final double averageBaitLevel;

  const DashboardSummary({
    required this.totalStations,
    required this.onlineStations,
    required this.offlineStations,
    required this.totalAlerts,
    required this.criticalAlerts,
    required this.averageBaitLevel,
  });
}
