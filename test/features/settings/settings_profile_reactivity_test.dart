import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/data/repositories/mock/mock_settings_repository.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/models/user_settings.dart';
import 'package:baitguard/features/settings/view_models/settings_view_model.dart';
import 'package:baitguard/features/settings/views/settings_screen.dart';

void main() {
  testWidgets('settings profile reacts to session update without recreation', (
    tester,
  ) async {
    final dataSource = MockBaitGuardDataSource.seeded();
    final originalUser = dataSource.users.firstWhere(
      (user) => user.role == UserRole.viewer,
    );
    final session = AppSessionController()..establishSession(originalUser);
    final facilityController = ActiveFacilityController(
      permittedSiteIds: originalUser.siteAccessIds,
    );
    final settingsViewModel = SettingsViewModel(
      settingsRepository: MockSettingsRepository(dataSource),
      sessionController: session,
      activeFacilityController: facilityController,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppSessionController>.value(value: session),
            ChangeNotifierProvider<ActiveFacilityController>.value(
              value: facilityController,
            ),
            ChangeNotifierProvider<SettingsViewModel>.value(
              value: settingsViewModel,
            ),
          ],
          child: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    session.establishSession(
      originalUser.copyWith(
        name: 'Wajeeha Kamran',
        firstName: 'Wajeeha',
        lastName: 'Kamran',
      ),
    );
    await tester.pump();

    expect(find.text('Wajeeha Kamran'), findsOneWidget);
    expect(find.text('WK'), findsOneWidget);
    expect(find.text('Warehouse A'), findsWidgets);

    await settingsViewModel.applySavedSettings(
      settingsViewModel.settings!.copyWith(
        defaultView: DefaultViewType.grid,
        defaultAlertFilter: AlertFilterType.offline,
      ),
    );
    await tester.pump();

    expect(find.text('Grid'), findsOneWidget);
    expect(find.text('Offline Only'), findsOneWidget);
  });
}
