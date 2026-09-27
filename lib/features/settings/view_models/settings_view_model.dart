import 'package:flutter/foundation.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/user_settings.dart';
import '../../../domain/models/notification_preferences.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../app/state/active_facility_controller.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepository;
  final AppSessionController _sessionController;
  final ActiveFacilityController _activeFacilityController;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  UserSettings? _settings;
  String? _activeFacilityName;

  int _actionSuccessEventId = 0;
  int _actionErrorEventId = 0;

  SettingsViewModel({
    required SettingsRepository settingsRepository,
    required AppSessionController sessionController,
    required ActiveFacilityController activeFacilityController,
  }) : _settingsRepository = settingsRepository,
       _sessionController = sessionController,
       _activeFacilityController = activeFacilityController {
    _load();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserSettings? get settings => _settings;
  String? get activeFacilityName => _activeFacilityName;
  AppUser? get currentUser => _sessionController.currentUser;
  ActiveFacilityController get facilityController => _activeFacilityController;

  int get actionSuccessEventId => _actionSuccessEventId;
  String? get actionSuccessMessage => _successMessage;
  int get actionErrorEventId => _actionErrorEventId;
  String? get actionErrorMessage => _errorMessage;

  Future<void> _load() async {
    final user = currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _settingsRepository.getSettings(user.id);
      final siteId =
          _settings!.defaultFacilityId ??
          _activeFacilityController.selectedSiteId;
      _activeFacilityName = siteId == null
          ? null
          : await _settingsRepository.getFacilityDisplayName(siteId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load settings';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applySavedSettings(UserSettings settings) async {
    _settings = settings;
    final facilityId =
        settings.defaultFacilityId ?? _activeFacilityController.selectedSiteId;
    _activeFacilityName = facilityId == null
        ? null
        : await _settingsRepository.getFacilityDisplayName(facilityId);
    notifyListeners();
  }

  Future<void> updateNotifications(
    NotificationPreferences newPrefs,
    String toggleName,
    bool isEnabled,
  ) async {
    if (_settings == null) return;

    // Optimistic update
    final updatedSettings = _settings!.copyWith(notifications: newPrefs);
    _settings = updatedSettings;
    notifyListeners();

    try {
      await _settingsRepository.updateSettings(updatedSettings);
      _actionSuccessEventId++;
      _successMessage = '$toggleName ${isEnabled ? 'enabled' : 'disabled'}';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update preferences';
      _actionErrorEventId++;
      notifyListeners();
      await _load();
    }
  }
}
