import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../dashboard/view_models/user_dashboard_view_model.dart';
import '../../dashboard/views/user_dashboard_screen.dart';
import '../../stations/navigation/stations_flow_navigator.dart';
import '../../reports/navigation/reports_flow_navigator.dart';
import '../widgets/authenticated_bottom_navigation.dart';
import '../../alerts/navigation/alerts_flow_navigator.dart';

class UserAppShell extends StatefulWidget {
  const UserAppShell({super.key});

  @override
  State<UserAppShell> createState() => _UserAppShellState();
}

class _UserAppShellState extends State<UserAppShell> {
  final GlobalKey<AlertsFlowNavigatorState> _alertsNavigatorKey =
      GlobalKey<AlertsFlowNavigatorState>();
  final GlobalKey<StationsFlowNavigatorState> _stationsNavigatorKey =
      GlobalKey<StationsFlowNavigatorState>();
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      if (index == 2) {
        _alertsNavigatorKey.currentState?.showList();
      }
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void openAlertDetail(String alertId) {
    setState(() {
      _currentIndex = 2;
    });
    // Need a tiny delay for navigator to be built if it was offstage or not initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alertsNavigatorKey.currentState?.openAlertDetail(alertId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadAlertCount = context.select<UserDashboardViewModel, int>(
      (vm) => vm.data?.unreadAlertCount ?? 0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            UserDashboardScreen(
              onSelectTab: _onTabTapped,
              onAlertTap: openAlertDetail,
              onStationTap: (stationId) {
                setState(() {
                  _currentIndex = 1;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _stationsNavigatorKey.currentState?.openStationDetail(
                    stationId,
                  );
                });
              },
            ),
            // Screen 08 — Stations nested flow
            StationsFlowNavigator(key: _stationsNavigatorKey),
            // Screen 09 — Alerts nested flow
            AlertsFlowNavigator(key: _alertsNavigatorKey),
            // Screen 14 - Reports nested flow
            ReportsFlowNavigator(
              onStationTap: (stationId) {
                setState(() {
                  _currentIndex = 1;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _stationsNavigatorKey.currentState?.openStationDetail(
                    stationId,
                  );
                });
              },
            ),
          ],
        ),
        bottomNavigationBar: AuthenticatedBottomNavigation(
          selectedIndex: _currentIndex,
          unreadAlertCount: unreadAlertCount,
          onSelected: _onTabTapped,
        ),
      ),
    );
  }
}
