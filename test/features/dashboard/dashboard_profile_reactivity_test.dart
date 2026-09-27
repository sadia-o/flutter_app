import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/data/repositories/mock/mock_dashboard_repository.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/features/dashboard/view_models/user_dashboard_view_model.dart';
import 'package:baitguard/features/dashboard/views/user_dashboard_screen.dart';

void main() {
  testWidgets('user dashboard reacts to session identity without data reload', (
    tester,
  ) async {
    final dataSource = MockBaitGuardDataSource.seeded();
    final originalUser = dataSource.users.firstWhere(
      (user) => user.role == UserRole.viewer,
    );
    final session = AppSessionController()..establishSession(originalUser);
    final viewModel = UserDashboardViewModel(
      dashboardRepository: MockDashboardRepository(dataSource),
      sessionController: session,
    );
    await tester.runAsync(() => viewModel.load());
    final originalDashboardData = viewModel.data;

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppSessionController>.value(value: session),
            ChangeNotifierProvider<ActiveFacilityController>(
              create: (_) => ActiveFacilityController(
                permittedSiteIds: originalUser.siteAccessIds,
              ),
            ),
            ChangeNotifierProvider<UserDashboardViewModel>.value(
              value: viewModel,
            ),
          ],
          child: UserDashboardScreen(onSelectTab: (_) {}),
        ),
      ),
    );

    final updatedUser = AppUser(
      id: originalUser.id,
      name: 'Alexander Christopher Rivera',
      email: originalUser.email,
      role: originalUser.role,
      siteAccessIds: originalUser.siteAccessIds,
      firstName: 'Alexander',
      lastName: 'Christopher Rivera',
    );
    session.establishSession(updatedUser);
    await tester.pump();

    expect(find.text('Alexander Christopher Rivera'), findsOneWidget);
    expect(find.text('AC'), findsOneWidget);
    expect(viewModel.data, same(originalDashboardData));
    expect(tester.takeException(), isNull);
  });

  testWidgets('user dashboard header handles the longest supported name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dataSource = MockBaitGuardDataSource.seeded();
    final originalUser = dataSource.users.firstWhere(
      (user) => user.role == UserRole.viewer,
    );
    final longNameUser = originalUser.copyWith(
      name: 'Muhammad Abdul Rehman Khan',
      firstName: 'Muhammad',
      lastName: 'Abdul Rehman Khan',
    );
    final session = AppSessionController()..establishSession(longNameUser);
    final viewModel = UserDashboardViewModel(
      dashboardRepository: MockDashboardRepository(dataSource),
      sessionController: session,
    );
    await tester.runAsync(() => viewModel.load());

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppSessionController>.value(value: session),
            ChangeNotifierProvider<ActiveFacilityController>(
              create: (_) => ActiveFacilityController(
                permittedSiteIds: originalUser.siteAccessIds,
              ),
            ),
            ChangeNotifierProvider<UserDashboardViewModel>.value(
              value: viewModel,
            ),
          ],
          child: UserDashboardScreen(onSelectTab: (_) {}),
        ),
      ),
    );

    expect(find.text('Muhammad Abdul Rehman Khan'), findsOneWidget);
    expect(find.text('MA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
