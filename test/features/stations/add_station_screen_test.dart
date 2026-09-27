import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:baitguard/features/stations/views/add_station_screen.dart';
import 'package:baitguard/features/stations/view_models/add_station_view_model.dart';
import 'package:baitguard/domain/models/site.dart';
import 'package:baitguard/domain/models/register_station_request.dart';
import 'package:baitguard/data/repositories/mock/mock_station_repository.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/app/state/active_facility_controller.dart';
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

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<AddStationViewModel>.value(
        value: viewModel,
        child: const AddStationScreen(),
      ),
    );
  }

  group('AddStationScreen', () {
    testWidgets(
      '1 & 2. Register Station button is part of the scrollable form',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final buttonFinder = find.widgetWithText(
          ElevatedButton,
          'Register Station',
        );

        final scrollableFinder = find.ancestor(
          of: buttonFinder,
          matching: find.byType(SingleChildScrollView),
        );

        expect(scrollableFinder, findsOneWidget);

        await tester.ensureVisible(buttonFinder);
        expect(buttonFinder, findsOneWidget);
      },
    );

    testWidgets('3 & 4. Selecting radio buttons triggers ViewModel updates', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final lteRadio = find.text('4G / LTE');
      await tester.ensureVisible(lteRadio);
      await tester.tap(lteRadio);
      await tester.pumpAndSettle();

      expect(viewModel.connectivityType, StationConnectivityType.cellular);

      final loraRadio = find.text('LoRaWAN');
      await tester.ensureVisible(loraRadio);
      await tester.tap(loraRadio);
      await tester.pumpAndSettle();

      expect(viewModel.connectivityType, StationConnectivityType.lorawan);
    });

    testWidgets('9-12. Notification toggles trigger ViewModel updates', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find the switches by looking near their labels
      final rodentSwitch = find.byType(Switch).at(0);
      await tester.ensureVisible(rodentSwitch);
      await tester.tap(rodentSwitch);
      await tester.pumpAndSettle();

      // The default is true in StationAlertPreferences.defaults(), so tapping it should make it false
      expect(viewModel.alertPreferences.rodentDetection, isFalse);
    });
  });
}
