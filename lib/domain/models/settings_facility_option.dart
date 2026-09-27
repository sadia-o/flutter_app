class SettingsFacilityOption {
  final String id;
  final String name;
  final int stationCount;
  final int offlineStationCount;

  const SettingsFacilityOption({
    required this.id,
    required this.name,
    required this.stationCount,
    required this.offlineStationCount,
  });

  bool get isHealthy => offlineStationCount == 0;
}
