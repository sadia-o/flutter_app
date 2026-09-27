import 'notification_preferences.dart';

enum DefaultViewType { map, list, grid }

enum AlertFilterType { all, rodent, lowBait, tamper, offline }

class UserSettings {
  final String userId;
  final NotificationPreferences notifications;
  final DefaultViewType defaultView;
  final String? defaultFacilityId;
  final AlertFilterType defaultAlertFilter;

  const UserSettings({
    required this.userId,
    required this.notifications,
    this.defaultView = DefaultViewType.list,
    this.defaultFacilityId,
    this.defaultAlertFilter = AlertFilterType.all,
  });

  UserSettings copyWith({
    NotificationPreferences? notifications,
    DefaultViewType? defaultView,
    String? defaultFacilityId,
    AlertFilterType? defaultAlertFilter,
  }) {
    return UserSettings(
      userId: userId,
      notifications: notifications ?? this.notifications,
      defaultView: defaultView ?? this.defaultView,
      defaultFacilityId: defaultFacilityId ?? this.defaultFacilityId,
      defaultAlertFilter: defaultAlertFilter ?? this.defaultAlertFilter,
    );
  }
}
