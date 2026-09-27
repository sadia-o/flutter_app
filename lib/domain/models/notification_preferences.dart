class NotificationPreferences {
  final bool rodentAlerts;
  final bool lowBaitAlerts;
  final bool tamperAlerts;
  final bool stationOfflineAlerts;
  final bool pushAlerts;
  final bool emailAlerts;

  const NotificationPreferences({
    this.rodentAlerts = true,
    this.lowBaitAlerts = true,
    this.tamperAlerts = true,
    this.stationOfflineAlerts = true,
    this.pushAlerts = true,
    this.emailAlerts = true,
  });

  NotificationPreferences copyWith({
    bool? rodentAlerts,
    bool? lowBaitAlerts,
    bool? tamperAlerts,
    bool? stationOfflineAlerts,
    bool? pushAlerts,
    bool? emailAlerts,
  }) {
    return NotificationPreferences(
      rodentAlerts: rodentAlerts ?? this.rodentAlerts,
      lowBaitAlerts: lowBaitAlerts ?? this.lowBaitAlerts,
      tamperAlerts: tamperAlerts ?? this.tamperAlerts,
      stationOfflineAlerts: stationOfflineAlerts ?? this.stationOfflineAlerts,
      pushAlerts: pushAlerts ?? this.pushAlerts,
      emailAlerts: emailAlerts ?? this.emailAlerts,
    );
  }
}
