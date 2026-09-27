import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baitguard/app/navigation/app_router.dart';
import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/administrator_contact.dart';
import 'package:baitguard/domain/models/notification_preferences.dart';
import 'package:baitguard/domain/models/settings_facility_option.dart';
import 'package:baitguard/domain/models/user_settings.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/settings_repository.dart';
import 'package:baitguard/features/settings/view_models/settings_preferences_view_model.dart';
import 'package:baitguard/features/settings/view_models/settings_view_model.dart';
import 'package:baitguard/features/settings/views/default_alert_filter_screen.dart';
import 'package:baitguard/features/settings/views/default_facility_screen.dart';
import 'package:baitguard/features/settings/views/default_view_screen.dart';
import 'package:baitguard/features/settings/views/settings_screen.dart';
import 'package:baitguard/features/settings/views/privacy_policy_screen.dart';
import 'package:baitguard/features/settings/views/terms_conditions_screen.dart';
import 'package:baitguard/domain/repositories/auth_repository.dart';
import 'package:baitguard/data/repositories/mock/mock_auth_repository.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/features/onboarding/views/welcome_screen.dart';

class _ScreenSettingsRepository implements SettingsRepository {
  UserSettings stored;
  int updateCount = 0;

  _ScreenSettingsRepository(this.stored);

  @override
  Future<UserSettings> getSettings(String userId) async => stored;

  @override
  Future<void> updateSettings(UserSettings settings) async {
    stored = settings;
    updateCount++;
  }

  @override
  Future<String?> getFacilityDisplayName(String siteId) async =>
      siteId == 'site_1' ? 'Warehouse A' : null;

  @override
  Future<List<SettingsFacilityOption>> getPermittedFacilities(
    List<String> permittedSiteIds,
  ) async {
    const all = [
      SettingsFacilityOption(
        id: 'site_1',
        name: 'Warehouse A',
        stationCount: 8,
        offlineStationCount: 0,
      ),
      SettingsFacilityOption(
        id: 'site_2',
        name: 'Secret Facility',
        stationCount: 5,
        offlineStationCount: 1,
      ),
    ];
    return all
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

class _TrackingActiveFacilityController extends ActiveFacilityController {
  bool wasDisposed = false;

  _TrackingActiveFacilityController({required super.permittedSiteIds});

  @override
  void dispose() {
    wasDisposed = true;
    super.dispose();
  }
}

UserSettings _storedSettings() {
  return const UserSettings(
    userId: 'viewer_1',
    notifications: NotificationPreferences(),
    defaultView: DefaultViewType.list,
    defaultFacilityId: 'site_1',
    defaultAlertFilter: AlertFilterType.all,
  );
}

Widget _app({
  required Widget screen,
  required SettingsPreferencesViewModel viewModel,
}) {
  return MaterialApp(
    home: ChangeNotifierProvider<SettingsPreferencesViewModel>.value(
      value: viewModel,
      child: screen,
    ),
  );
}

Widget _settingsFlowApp({
  required _ScreenSettingsRepository repository,
  required AppSessionController session,
  required ActiveFacilityController activeFacilityController,
}) {
  final dataSource = MockBaitGuardDataSource.seeded();
  return MultiProvider(
    providers: [
      Provider<SettingsRepository>.value(value: repository),
      Provider<AuthRepository>.value(value: MockAuthRepository(dataSource)),
      ChangeNotifierProvider<AppSessionController>.value(value: session),
    ],
    child: MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<ActiveFacilityController>.value(
            value: activeFacilityController,
          ),
          ChangeNotifierProvider<SettingsViewModel>(
            create: (_) => SettingsViewModel(
              settingsRepository: repository,
              sessionController: session,
              activeFacilityController: activeFacilityController,
            ),
          ),
        ],
        child: const SettingsScreen(),
      ),
    ),
  );
}

Future<void> _openDefaultFacility(WidgetTester tester) async {
  final row = find.text('Default Facility');
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> _openSettingsRow(WidgetTester tester, String label) async {
  final row = find.text(label);
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Default View shows persisted selection and Back does not save', (
    tester,
  ) async {
    final repository = _ScreenSettingsRepository(_storedSettings());
    final viewModel = SettingsPreferencesViewModel(
      repository: repository,
      initialSettings: repository.stored,
      permittedFacilityIds: const ['site_1'],
    );
    await tester.pumpWidget(
      _app(screen: const DefaultViewScreen(), viewModel: viewModel),
    );

    expect(viewModel.selectedView, DefaultViewType.list);
    await tester.tap(find.byKey(const ValueKey('defaultView_grid')));
    await tester.tap(find.byKey(const Key('settingsPreferenceBack')));
    await tester.pump();

    expect(repository.stored.defaultView, DefaultViewType.list);
    expect(repository.updateCount, 0);
  });

  testWidgets('Default View Save persists selected option', (tester) async {
    final repository = _ScreenSettingsRepository(_storedSettings());
    final viewModel = SettingsPreferencesViewModel(
      repository: repository,
      initialSettings: repository.stored,
      permittedFacilityIds: const ['site_1'],
    );
    await tester.pumpWidget(
      _app(screen: const DefaultViewScreen(), viewModel: viewModel),
    );

    await tester.tap(find.byKey(const ValueKey('defaultView_grid')));
    await tester.tap(find.byKey(const Key('savePreferenceButton')));
    await tester.pumpAndSettle();

    expect(repository.stored.defaultView, DefaultViewType.grid);
  });

  testWidgets('Alert Filter loads persisted value and saves only on Save', (
    tester,
  ) async {
    final repository = _ScreenSettingsRepository(_storedSettings());
    final viewModel = SettingsPreferencesViewModel(
      repository: repository,
      initialSettings: repository.stored,
      permittedFacilityIds: const ['site_1'],
    );
    await tester.pumpWidget(
      _app(screen: const DefaultAlertFilterScreen(), viewModel: viewModel),
    );

    expect(viewModel.selectedAlertFilter, AlertFilterType.all);
    await tester.tap(find.byKey(const ValueKey('alertFilter_offline')));
    expect(repository.stored.defaultAlertFilter, AlertFilterType.all);
    await tester.tap(find.byKey(const Key('savePreferenceButton')));
    await tester.pumpAndSettle();

    expect(repository.stored.defaultAlertFilter, AlertFilterType.offline);
  });

  testWidgets('Default Facility shows only friendly permitted facilities', (
    tester,
  ) async {
    final repository = _ScreenSettingsRepository(_storedSettings());
    final viewModel = SettingsPreferencesViewModel(
      repository: repository,
      initialSettings: repository.stored,
      permittedFacilityIds: const ['site_1'],
    );
    await tester.pumpWidget(
      _app(screen: const DefaultFacilityScreen(), viewModel: viewModel),
    );
    await tester.pumpAndSettle();

    expect(find.text('Warehouse A'), findsOneWidget);
    expect(find.text('Secret Facility'), findsNothing);
    expect(find.text('site_1'), findsNothing);
    expect(find.text('site_2'), findsNothing);
    expect(viewModel.selectedFacilityId, 'site_1');
  });

  testWidgets(
    'Default Facility route opens, backs, repeats, saves once, and preserves shared controller',
    (tester) async {
      final repository = _ScreenSettingsRepository(_storedSettings());
      final session = AppSessionController()
        ..establishSession(
          AppUser(
            id: 'viewer_1',
            name: 'Viewer User',
            email: 'user@baitguard.com',
            role: UserRole.viewer,
            siteAccessIds: const ['site_1'],
          ),
        );
      final activeFacilityController = _TrackingActiveFacilityController(
        permittedSiteIds: const ['site_1'],
      );
      addTearDown(activeFacilityController.dispose);

      await tester.pumpWidget(
        _settingsFlowApp(
          repository: repository,
          session: session,
          activeFacilityController: activeFacilityController,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _openDefaultFacility(tester);
      expect(find.text('Warehouse A'), findsOneWidget);
      expect(find.text('Secret Facility'), findsNothing);
      expect(find.text('site_1'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('settingsPreferenceBack')));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(repository.updateCount, 0);
      expect(activeFacilityController.wasDisposed, isFalse);
      expect(tester.takeException(), isNull);

      await _openDefaultFacility(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('savePreferenceButton')));
      await tester.pumpAndSettle();

      expect(repository.updateCount, 1);
      expect(find.text('Settings'), findsOneWidget);
      expect(activeFacilityController.selectedSiteId, 'site_1');
      expect(activeFacilityController.wasDisposed, isFalse);
      expect(activeFacilityController.selectSite('unauthorized'), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets('logout is safe after visiting Default Facility', (tester) async {
    final repository = _ScreenSettingsRepository(_storedSettings());
    final session = AppSessionController()
      ..establishSession(
        AppUser(
          id: 'viewer_1',
          name: 'Viewer User',
          email: 'user@baitguard.com',
          role: UserRole.viewer,
          siteAccessIds: const ['site_1'],
        ),
      );
    final activeFacilityController = _TrackingActiveFacilityController(
      permittedSiteIds: const ['site_1'],
    );
    addTearDown(activeFacilityController.dispose);

    await tester.pumpWidget(
      _settingsFlowApp(
        repository: repository,
        session: session,
        activeFacilityController: activeFacilityController,
      ),
    );
    await tester.pumpAndSettle();
    await _openDefaultFacility(tester);
    await tester.tap(find.byKey(const Key('settingsPreferenceBack')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final logout = find.text('Log Out');
    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();

    expect(session.isAuthenticated, isFalse);
    expect(activeFacilityController.wasDisposed, isFalse);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Batch 4 routes open, scroll, back, and reopen safely', (
    tester,
  ) async {
    final repository = _ScreenSettingsRepository(_storedSettings());
    final session = AppSessionController()
      ..establishSession(
        AppUser(
          id: 'viewer_1',
          name: 'Viewer User',
          email: 'user@baitguard.com',
          role: UserRole.viewer,
          siteAccessIds: const ['site_1'],
        ),
      );
    final activeFacilityController = _TrackingActiveFacilityController(
      permittedSiteIds: const ['site_1'],
    );
    addTearDown(activeFacilityController.dispose);

    await tester.pumpWidget(
      _settingsFlowApp(
        repository: repository,
        session: session,
        activeFacilityController: activeFacilityController,
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 2; index++) {
      await _openSettingsRow(tester, 'Change Password');
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('settingsPreferenceBack')));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _openSettingsRow(tester, 'Contact Administrator');
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('settingsPreferenceBack')));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'Privacy Policy renders all sections and scrolls on small screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

      expect(find.text('Information We Collect'), findsOneWidget);
      expect(find.text('How We Use Your Data'), findsOneWidget);
      expect(find.text('Data Storage & Security'), findsOneWidget);
      expect(find.text('Your Rights'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Your Rights'),
        250,
        scrollable: find.descendant(
          of: find.byKey(const Key('legalScreenScroll')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Terms and Conditions renders all sections and scrolls on small screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: TermsConditionsScreen()));

      expect(find.text('Acceptance of Terms'), findsOneWidget);
      expect(find.text('Use of Service'), findsOneWidget);
      expect(find.text('User Responsibilities'), findsOneWidget);
      expect(find.text('Limitation of Liability'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Limitation of Liability'),
        250,
        scrollable: find.descendant(
          of: find.byKey(const Key('legalScreenScroll')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'legal Settings rows open correct routes repeatedly and Back returns safely',
    (tester) async {
      final repository = _ScreenSettingsRepository(_storedSettings());
      final session = AppSessionController()
        ..establishSession(
          AppUser(
            id: 'viewer_1',
            name: 'Viewer User',
            email: 'user@baitguard.com',
            role: UserRole.viewer,
            siteAccessIds: const ['site_1'],
          ),
        );
      final activeFacilityController = _TrackingActiveFacilityController(
        permittedSiteIds: const ['site_1'],
      );
      addTearDown(activeFacilityController.dispose);

      await tester.pumpWidget(
        _settingsFlowApp(
          repository: repository,
          session: session,
          activeFacilityController: activeFacilityController,
        ),
      );
      await tester.pumpAndSettle();

      for (var index = 0; index < 2; index++) {
        await _openSettingsRow(tester, 'Privacy Policy');
        expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('legalScreenBack')));
        await tester.pumpAndSettle();
        expect(find.text('Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _openSettingsRow(tester, 'Terms & Conditions');
        expect(find.byType(TermsConditionsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('legalScreenBack')));
        await tester.pumpAndSettle();
        expect(find.text('Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('logout remains safe after visiting both legal screens', (
    tester,
  ) async {
    final repository = _ScreenSettingsRepository(_storedSettings());
    final session = AppSessionController()
      ..establishSession(
        AppUser(
          id: 'viewer_1',
          name: 'Viewer User',
          email: 'user@baitguard.com',
          role: UserRole.viewer,
          siteAccessIds: const ['site_1'],
        ),
      );
    final activeFacilityController = _TrackingActiveFacilityController(
      permittedSiteIds: const ['site_1'],
    );
    addTearDown(activeFacilityController.dispose);

    await tester.pumpWidget(
      _settingsFlowApp(
        repository: repository,
        session: session,
        activeFacilityController: activeFacilityController,
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Privacy Policy', 'Terms & Conditions']) {
      await _openSettingsRow(tester, label);
      await tester.tap(find.byKey(const Key('legalScreenBack')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    final logout = find.text('Log Out');
    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();

    expect(session.isAuthenticated, isFalse);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
