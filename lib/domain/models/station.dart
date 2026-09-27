import 'station_status.dart';

class Station {
  final String id;
  final String name;
  final String siteId;
  final String locationDescription;
  final StationStatus status;
  final double baitPercentage;
  final double batteryPercentage;
  final double? temperature;
  final double? humidity;
  final bool isTampered;
  final bool hasTamperData;
  final DateTime lastSeen;

  // Operational state fields added for Screen 08
  final bool notificationsMuted;
  final bool hasCamera;
  final DateTime? lastRefilledAt;

  const Station({
    required this.id,
    required this.name,
    required this.siteId,
    required this.locationDescription,
    required this.status,
    required this.baitPercentage,
    required this.batteryPercentage,
    this.temperature,
    this.humidity,
    this.isTampered = false,
    this.hasTamperData = true,
    required this.lastSeen,
    this.notificationsMuted = false,
    this.hasCamera = false,
    this.lastRefilledAt,
  });

  /// Returns a new Station with the provided fields replaced.
  Station copyWith({
    String? id,
    String? name,
    String? siteId,
    String? locationDescription,
    StationStatus? status,
    double? baitPercentage,
    double? batteryPercentage,
    double? temperature,
    double? humidity,
    bool? isTampered,
    bool? hasTamperData,
    DateTime? lastSeen,
    bool? notificationsMuted,
    bool? hasCamera,
    DateTime? lastRefilledAt,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      siteId: siteId ?? this.siteId,
      locationDescription: locationDescription ?? this.locationDescription,
      status: status ?? this.status,
      baitPercentage: baitPercentage ?? this.baitPercentage,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      isTampered: isTampered ?? this.isTampered,
      hasTamperData: hasTamperData ?? this.hasTamperData,
      lastSeen: lastSeen ?? this.lastSeen,
      notificationsMuted: notificationsMuted ?? this.notificationsMuted,
      hasCamera: hasCamera ?? this.hasCamera,
      lastRefilledAt: lastRefilledAt ?? this.lastRefilledAt,
    );
  }

  bool get isOnline => status != StationStatus.offline;
}

/// Default low bait threshold across BaitGuard.
const double kLowBaitThreshold = 25.0;

/// Returns true when [station] is considered to have low bait.
bool stationIsLowBait(Station station) =>
    station.baitPercentage <= kLowBaitThreshold;

/// Returns true when [station] requires operational attention.
/// Covers alert status, tampered, and offline states.
bool stationNeedsAttention(Station station) =>
    station.status == StationStatus.alert ||
    station.status == StationStatus.offline ||
    station.isTampered;

/// Returns true when [station] is considered connected / online.
bool stationIsConnected(Station station) =>
    station.status != StationStatus.offline;
