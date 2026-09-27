class StationAlertPreferences {
  final bool rodentDetection;
  final bool lowBait;
  final bool tamper;
  final bool stationOffline;

  const StationAlertPreferences({
    required this.rodentDetection,
    required this.lowBait,
    required this.tamper,
    required this.stationOffline,
  });

  factory StationAlertPreferences.defaults() {
    return const StationAlertPreferences(
      rodentDetection: true,
      lowBait: true,
      tamper: true,
      stationOffline: true,
    );
  }
}

enum StationConnectivityType { wifi, cellular, lorawan }

class RegisterStationRequest {
  final String stationId;
  final String stationName;
  final String siteId;
  final String zoneLocation;
  final StationConnectivityType connectivityType;
  final String? wifiNetworkName;
  final StationAlertPreferences alertPreferences;

  const RegisterStationRequest({
    required this.stationId,
    required this.stationName,
    required this.siteId,
    required this.zoneLocation,
    required this.connectivityType,
    this.wifiNetworkName,
    required this.alertPreferences,
  });
}
