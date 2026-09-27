import '../../../domain/models/user_settings.dart';
import '../../../domain/models/notification_preferences.dart';
import '../../../domain/models/settings_facility_option.dart';
import '../../../domain/models/station_status.dart';
import '../../../domain/models/administrator_contact.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/settings_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockSettingsRepository implements SettingsRepository {
  final MockBaitGuardDataSource _dataSource;

  MockSettingsRepository(this._dataSource);

  @override
  Future<UserSettings> getSettings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Check data source cache first
    var settings = _dataSource.getUserSettings(userId);
    if (settings == null) {
      // Return default if not set
      settings = UserSettings(
        userId: userId,
        notifications: const NotificationPreferences(),
      );
      _dataSource.updateUserSettings(settings);
    }
    return settings;
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _dataSource.updateUserSettings(settings);
  }

  @override
  Future<String?> getFacilityDisplayName(String siteId) async {
    for (final site in _dataSource.sites) {
      if (site.id == siteId) return site.name;
    }
    return null;
  }

  @override
  Future<List<SettingsFacilityOption>> getPermittedFacilities(
    List<String> permittedSiteIds,
  ) async {
    final permittedIds = permittedSiteIds.toSet();
    return _dataSource.sites
        .where((site) => permittedIds.contains(site.id))
        .map((site) {
          final stations = _dataSource.stations
              .where((station) => station.siteId == site.id)
              .toList();
          return SettingsFacilityOption(
            id: site.id,
            name: site.name,
            stationCount: stations.length,
            offlineStationCount: stations
                .where((station) => station.status == StationStatus.offline)
                .length,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Frontend-only success simulation. Password values are intentionally
    // neither inspected nor written to MockBaitGuardDataSource.
  }

  @override
  Future<AdministratorContact> getAdministratorContact(String userId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final administrator = _dataSource.users.firstWhere(
      (user) => user.role == UserRole.admin && user.isActive,
    );
    return AdministratorContact(
      id: administrator.id,
      name: administrator.name,
      roleLabel: 'SYSTEM ADMINISTRATOR',
      email: administrator.email,
      phoneNumber: administrator.phoneNumber,
    );
  }

  @override
  Future<void> sendAdministratorMessage({
    required String userId,
    required String administratorId,
    required String message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Frontend-only success simulation. No message or external action occurs.
  }
}
