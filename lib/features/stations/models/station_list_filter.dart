/// Filter options for the Stations list.
///
/// Used by StationsViewModel to filter the station list locally.
/// Do not use visible display labels as business logic.
enum StationListFilter {
  /// All stations loaded for the active permitted facility.
  all,

  /// Stations requiring operational attention:
  /// status == alert, isTampered, or status == offline.
  alerts,

  /// Stations with baitPercentage at or below kLowBaitThreshold (25%).
  lowBait,

  /// Connected stations — all statuses except offline.
  /// Note: connectivity may later become a separate backend field.
  online,
}
