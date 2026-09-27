import 'package:flutter_test/flutter_test.dart';

import 'package:baitguard/domain/models/notification_preferences.dart';
import 'package:baitguard/domain/models/administrator_contact.dart';
import 'package:baitguard/domain/models/settings_facility_option.dart';
import 'package:baitguard/domain/models/user_settings.dart';
import 'package:baitguard/domain/repositories/settings_repository.dart';
import 'package:baitguard/features/settings/view_models/settings_preferences_view_model.dart';

class _MemorySettingsRepository implements SettingsRepository {
  UserSettings stored;
  List<SettingsFacilityOption> availableFacilities;
  int updateCount = 0;

  _MemorySettingsRepository({
    required this.stored,
    this.availableFacilities = const [],
  });

  @override
  Future<UserSettings> getSettings(String userId) async => stored;

  @override
  Future<void> updateSettings(UserSettings settings) async {
    stored = settings;
    updateCount++;
  }

  @override
  Future<String?> getFacilityDisplayName(String siteId) async {
    for (final facility in availableFacilities) {
      if (facility.id == siteId) return facility.name;
    }
    return null;
  }

  @override
  Future<List<SettingsFacilityOption>> getPermittedFacilities(
    List<String> permittedSiteIds,
  ) async {
    return availableFacilities
        .where((facility) => permittedSiteIds.contains(facility.id))
        .toList();
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<AdministratorContact> getAdministratorContact(String userId) async =>
      const AdministratorContact(
        id: 'admin_1',
        name: 'Alex Rivera',
        roleLabel: 'SYSTEM ADMINISTRATOR',
        email: 'admin@baitguard.com',
      );

  @override
  Future<void> sendAdministratorMessage({
    required String userId,
    required String administratorId,
    required String message,
  }) async {}
}

UserSettings _settings({
  DefaultViewType view = DefaultViewType.list,
  String? facilityId = 'site_1',
  AlertFilterType filter = AlertFilterType.all,
}) {
  return UserSettings(
    userId: 'viewer_1',
    notifications: const NotificationPreferences(),
    defaultView: view,
    defaultFacilityId: facilityId,
    defaultAlertFilter: filter,
  );
}

void main() {
  test('loads current persisted draft selections', () {
    final stored = _settings(
      view: DefaultViewType.grid,
      facilityId: 'site_2',
      filter: AlertFilterType.tamper,
    );
    final viewModel = SettingsPreferencesViewModel(
      repository: _MemorySettingsRepository(stored: stored),
      initialSettings: stored,
      permittedFacilityIds: const ['site_1', 'site_2'],
    );

    expect(viewModel.selectedView, DefaultViewType.grid);
    expect(viewModel.selectedFacilityId, 'site_2');
    expect(viewModel.selectedAlertFilter, AlertFilterType.tamper);
  });

  test('changing view draft does not persist until save', () async {
    final repository = _MemorySettingsRepository(stored: _settings());
    final viewModel = SettingsPreferencesViewModel(
      repository: repository,
      initialSettings: repository.stored,
      permittedFacilityIds: const ['site_1'],
    );

    viewModel.selectView(DefaultViewType.map);

    expect(repository.stored.defaultView, DefaultViewType.list);
    expect(repository.updateCount, 0);

    await viewModel.saveView();

    expect(repository.stored.defaultView, DefaultViewType.map);
    expect(repository.updateCount, 1);
  });

  test('changing alert-filter draft does not persist until save', () async {
    final repository = _MemorySettingsRepository(stored: _settings());
    final viewModel = SettingsPreferencesViewModel(
      repository: repository,
      initialSettings: repository.stored,
      permittedFacilityIds: const ['site_1'],
    );

    viewModel.selectAlertFilter(AlertFilterType.offline);

    expect(repository.stored.defaultAlertFilter, AlertFilterType.all);
    expect(repository.updateCount, 0);

    await viewModel.saveAlertFilter();

    expect(repository.stored.defaultAlertFilter, AlertFilterType.offline);
  });

  test('facility loading excludes unauthorized facilities', () async {
    final repository = _MemorySettingsRepository(
      stored: _settings(),
      availableFacilities: const [
        SettingsFacilityOption(
          id: 'site_1',
          name: 'Warehouse A',
          stationCount: 8,
          offlineStationCount: 0,
        ),
        SettingsFacilityOption(
          id: 'site_2',
          name: 'Warehouse B',
          stationCount: 12,
          offlineStationCount: 2,
        ),
      ],
    );
    final viewModel = SettingsPreferencesViewModel(
      repository: repository,
      initialSettings: repository.stored,
      permittedFacilityIds: const ['site_1'],
    );

    await viewModel.loadFacilities();

    expect(viewModel.facilities.map((facility) => facility.name), [
      'Warehouse A',
    ]);
    expect(
      viewModel.facilities.any((facility) => facility.id == 'site_2'),
      isFalse,
    );
  });

  test('facility draft persists only after save', () async {
    final repository = _MemorySettingsRepository(
      stored: _settings(),
      availableFacilities: const [
        SettingsFacilityOption(
          id: 'site_1',
          name: 'Warehouse A',
          stationCount: 8,
          offlineStationCount: 0,
        ),
        SettingsFacilityOption(
          id: 'site_2',
          name: 'Warehouse B',
          stationCount: 12,
          offlineStationCount: 2,
        ),
      ],
    );
    final viewModel = SettingsPreferencesViewModel(
      repository: repository,
      initialSettings: repository.stored,
      permittedFacilityIds: const ['site_1', 'site_2'],
    );
    await viewModel.loadFacilities();

    viewModel.selectFacility('site_2');
    expect(repository.stored.defaultFacilityId, 'site_1');

    await viewModel.saveFacility();
    expect(repository.stored.defaultFacilityId, 'site_2');
  });

  test('unauthorized facility selection is ignored', () async {
    final repository = _MemorySettingsRepository(
      stored: _settings(),
      availableFacilities: const [
        SettingsFacilityOption(
          id: 'site_1',
          name: 'Warehouse A',
          stationCount: 8,
          offlineStationCount: 0,
        ),
      ],
    );
    final viewModel = SettingsPreferencesViewModel(
      repository: repository,
      initialSettings: repository.stored,
      permittedFacilityIds: const ['site_1'],
    );
    await viewModel.loadFacilities();

    viewModel.selectFacility('site_99');

    expect(viewModel.selectedFacilityId, 'site_1');
  });
}
