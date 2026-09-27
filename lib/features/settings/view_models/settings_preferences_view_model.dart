import 'package:flutter/foundation.dart';

import '../../../domain/models/settings_facility_option.dart';
import '../../../domain/models/user_settings.dart';
import '../../../domain/repositories/settings_repository.dart';

class SettingsPreferencesRouteArguments {
  final UserSettings settings;
  final List<String> permittedFacilityIds;

  const SettingsPreferencesRouteArguments({
    required this.settings,
    required this.permittedFacilityIds,
  });
}

class SettingsPreferencesViewModel extends ChangeNotifier {
  final SettingsRepository _repository;
  final UserSettings initialSettings;
  final List<String> permittedFacilityIds;

  late DefaultViewType selectedView;
  late AlertFilterType selectedAlertFilter;
  String? selectedFacilityId;

  List<SettingsFacilityOption> _facilities = const [];
  bool _isLoadingFacilities = false;
  bool _isSaving = false;
  bool _isDisposed = false;
  String? _errorMessage;

  SettingsPreferencesViewModel({
    required SettingsRepository repository,
    required this.initialSettings,
    required this.permittedFacilityIds,
  }) : _repository = repository {
    selectedView = initialSettings.defaultView;
    selectedAlertFilter = initialSettings.defaultAlertFilter;
    selectedFacilityId = initialSettings.defaultFacilityId;
  }

  List<SettingsFacilityOption> get facilities => _facilities;
  bool get isLoadingFacilities => _isLoadingFacilities;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  void selectView(DefaultViewType value) {
    if (selectedView == value) return;
    selectedView = value;
    notifyListeners();
  }

  void selectAlertFilter(AlertFilterType value) {
    if (selectedAlertFilter == value) return;
    selectedAlertFilter = value;
    notifyListeners();
  }

  void selectFacility(String facilityId) {
    if (!_facilities.any((facility) => facility.id == facilityId)) return;
    if (selectedFacilityId == facilityId) return;
    selectedFacilityId = facilityId;
    notifyListeners();
  }

  Future<void> loadFacilities() async {
    if (_isLoadingFacilities || _isDisposed) return;
    _isLoadingFacilities = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final facilities = await _repository.getPermittedFacilities(
        permittedFacilityIds,
      );
      if (_isDisposed) return;
      _facilities = facilities;
      if (!_facilities.any((facility) => facility.id == selectedFacilityId)) {
        selectedFacilityId = _facilities.isEmpty ? null : _facilities.first.id;
      }
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = 'Failed to load facilities.';
    } finally {
      if (!_isDisposed) {
        _isLoadingFacilities = false;
        notifyListeners();
      }
    }
  }

  Future<UserSettings?> saveView() =>
      _save(initialSettings.copyWith(defaultView: selectedView));

  Future<UserSettings?> saveAlertFilter() =>
      _save(initialSettings.copyWith(defaultAlertFilter: selectedAlertFilter));

  Future<UserSettings?> saveFacility() async {
    final facilityId = selectedFacilityId;
    if (facilityId == null ||
        !_facilities.any((facility) => facility.id == facilityId)) {
      _errorMessage = 'Select an available facility.';
      notifyListeners();
      return null;
    }
    return _save(initialSettings.copyWith(defaultFacilityId: facilityId));
  }

  Future<UserSettings?> _save(UserSettings settings) async {
    if (_isSaving || _isDisposed) return null;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateSettings(settings);
      if (_isDisposed) return null;
      return settings;
    } catch (_) {
      if (_isDisposed) return null;
      _errorMessage = 'Failed to save preference. Please try again.';
      return null;
    } finally {
      if (!_isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
