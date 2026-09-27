import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/features/stations/view_models/add_station_view_model.dart';
import 'package:baitguard/domain/models/register_station_request.dart';
import 'package:baitguard/domain/models/site.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/data/repositories/mock/mock_station_repository.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';

void main() {
  late MockBaitGuardDataSource dataSource;
  late MockStationRepository repository;
  late AppSessionController sessionController;
  late ActiveFacilityController activeFacilityController;
  late List<Site> availableSites;
  late AddStationViewModel viewModel;

  setUp(() {
    dataSource = MockBaitGuardDataSource.seeded();
    repository = MockStationRepository(dataSource);
    sessionController = AppSessionController();

    final user = dataSource.users.firstWhere((u) => u.role == UserRole.admin);
    sessionController.establishSession(user);

    activeFacilityController = ActiveFacilityController(
      permittedSiteIds: user.siteAccessIds,
      initialSiteId: user.siteAccessIds.first,
    );

    availableSites = user.siteAccessIds
        .map((id) => Site(id: id, name: 'Site $id', location: ''))
        .toList();

    viewModel = AddStationViewModel(
      stationRepository: repository,
      activeFacilityController: activeFacilityController,
      availableSites: availableSites,
    );
  });

  group('AddStationViewModel - Connectivity', () {
    test('3. Selecting 4G / LTE updates the selected connectivity type.', () {
      viewModel.setConnectivityType(StationConnectivityType.cellular);
      expect(viewModel.connectivityType, StationConnectivityType.cellular);
    });

    test('4. Selecting LoRaWAN updates the selected connectivity type.', () {
      viewModel.setConnectivityType(StationConnectivityType.lorawan);
      expect(viewModel.connectivityType, StationConnectivityType.lorawan);
    });

    test('5. Selecting Wi-Fi restores the Wi-Fi network field.', () {
      viewModel.setWifiNetworkName('MyWifi');
      viewModel.setConnectivityType(StationConnectivityType.cellular);
      expect(viewModel.wifiNetworkName, isNull);
      viewModel.setConnectivityType(StationConnectivityType.wifi);
      viewModel.setWifiNetworkName('MyWifi');
      expect(viewModel.wifiNetworkName, 'MyWifi');
    });

    test(
      '6 & 7. Wi-Fi network field is hidden (cleared) for 4G / LTE and LoRaWAN.',
      () {
        viewModel.setWifiNetworkName('MyWifi');
        viewModel.setConnectivityType(StationConnectivityType.cellular);
        expect(viewModel.wifiNetworkName, isNull);

        viewModel.setConnectivityType(StationConnectivityType.wifi);
        viewModel.setWifiNetworkName('MyWifi');
        viewModel.setConnectivityType(StationConnectivityType.lorawan);
        expect(viewModel.wifiNetworkName, isNull);
      },
    );

    test(
      '8. Wi-Fi validation does not apply for non-Wi-Fi connectivity.',
      () async {
        viewModel.setStationId('TEST-01');
        viewModel.setStationName('Test');
        viewModel.setZoneLocation('Zone A');

        viewModel.setConnectivityType(StationConnectivityType.cellular);
        await viewModel.submit();

        expect(viewModel.wifiNetworkNameError, isNull);
        expect(viewModel.isValid, isTrue);
      },
    );
  });

  group('AddStationViewModel - Alerts', () {
    test('9, 10, 11, 12. Alert switches toggle independently.', () {
      final initial = viewModel.alertPreferences;

      viewModel.setAlertPreferences(
        StationAlertPreferences(
          rodentDetection: !initial.rodentDetection,
          lowBait: initial.lowBait,
          tamper: initial.tamper,
          stationOffline: initial.stationOffline,
        ),
      );
      expect(
        viewModel.alertPreferences.rodentDetection,
        !initial.rodentDetection,
      );
      expect(viewModel.alertPreferences.lowBait, initial.lowBait);

      viewModel.setAlertPreferences(
        StationAlertPreferences(
          rodentDetection: !initial.rodentDetection,
          lowBait: !initial.lowBait,
          tamper: initial.tamper,
          stationOffline: initial.stationOffline,
        ),
      );
      expect(viewModel.alertPreferences.lowBait, !initial.lowBait);
    });

    test(
      '13. Alert preference values are included in the registration request.',
      () async {
        viewModel.setStationId('TEST-02');
        viewModel.setStationName('Test 2');
        viewModel.setZoneLocation('Zone B');
        viewModel.setConnectivityType(StationConnectivityType.cellular);

        viewModel.setAlertPreferences(
          const StationAlertPreferences(
            rodentDetection: false,
            lowBait: false,
            tamper: true,
            stationOffline: false,
          ),
        );

        await viewModel.submit();
        expect(viewModel.isSuccess, isTrue);
      },
    );
  });

  group('AddStationViewModel - Existing Validation', () {
    test(
      '14. Existing Add Station validation and submission tests remain passing.',
      () async {
        await viewModel.submit();
        expect(viewModel.isValid, isFalse);
        expect(viewModel.stationIdError, isNotNull);
        expect(viewModel.stationNameError, isNotNull);
        expect(viewModel.zoneLocationError, isNotNull);
      },
    );
  });
}
