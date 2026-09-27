import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/repositories/report_repository.dart';
import '../view_models/reports_view_model.dart';
import '../views/reports_screen.dart';
import '../views/recent_exports_screen.dart';

class ReportsFlowNavigator extends StatefulWidget {
  final void Function(String stationId)? onStationTap;

  const ReportsFlowNavigator({super.key, this.onStationTap});

  @override
  State<ReportsFlowNavigator> createState() => _ReportsFlowNavigatorState();
}

class _ReportsFlowNavigatorState extends State<ReportsFlowNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late ReportsViewModel _reportsViewModel;

  @override
  void initState() {
    super.initState();
    final sessionController = context.read<AppSessionController>();
    _reportsViewModel = ReportsViewModel(
      repository: context.read<ReportRepository>(),
      activeFacilityController: context.read<ActiveFacilityController>(),
      userRole: sessionController.currentUser!.role,
      currentUserId: sessionController.currentUser!.id,
    );
  }

  @override
  void dispose() {
    _reportsViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) {
        WidgetBuilder builder;

        switch (settings.name) {
          case '/':
            builder = (ctx) => ChangeNotifierProvider.value(
              value: _reportsViewModel,
              child: ReportsScreen(onStationTap: widget.onStationTap),
            );
            break;

          case '/recent-exports':
            builder = (ctx) => ChangeNotifierProvider.value(
              value: _reportsViewModel,
              child: const RecentExportsScreen(),
            );
            break;

          default:
            builder = (ctx) =>
                const Scaffold(body: Center(child: Text('Unknown route')));
        }

        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}
