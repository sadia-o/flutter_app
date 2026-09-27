import '../models/user_settings.dart';
import '../models/settings_facility_option.dart';
import '../models/administrator_contact.dart';

abstract class SettingsRepository {
  Future<UserSettings> getSettings(String userId);
  Future<void> updateSettings(UserSettings settings);
  Future<String?> getFacilityDisplayName(String siteId);
  Future<List<SettingsFacilityOption>> getPermittedFacilities(
    List<String> permittedSiteIds,
  );
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });
  Future<AdministratorContact> getAdministratorContact(String userId);
  Future<void> sendAdministratorMessage({
    required String userId,
    required String administratorId,
    required String message,
  });
}
