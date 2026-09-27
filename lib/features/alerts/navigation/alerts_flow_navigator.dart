import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/repositories/alert_repository.dart';
import '../../../domain/repositories/station_repository.dart';
import '../../../domain/models/alert.dart';
import '../../navigation/models/admin_alert_list_preset.dart';
import '../view_models/alerts_view_model.dart';
import '../view_models/alert_detail_view_model.dart';
import '../views/alerts_screen.dart';
import '../views/alert_detail_screen.dart';
import '../../stations/views/station_detail_screen.dart';
import '../../stations/view_models/station_detail_view_model.dart';

class AlertsFlowNavigator extends StatefulWidget {
  final AdminAlertListPreset? initialPreset;

  const AlertsFlowNavigator({super.key, this.initialPreset});

  @override
  State<AlertsFlowNavigator> createState() => AlertsFlowNavigatorState();
}

class AlertsFlowNavigatorState extends State<AlertsFlowNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AlertsViewModel _alertsViewModel;

  @override
  void initState() {
    super.initState();
    _alertsViewModel = AlertsViewModel(
      alertRepository: context.read<AlertRepository>(),
      stationRepository: context.read<StationRepository>(),
      sessionController: context.read<AppSessionController>(),
      activeFacilityController: context.read<ActiveFacilityController>(),
    );
    if (widget.initialPreset != null) {
      _alertsViewModel.applyPreset(widget.initialPreset!);
    }
  }

  @override
  void didUpdateWidget(covariant AlertsFlowNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPreset != null &&
        widget.initialPreset != oldWidget.initialPreset) {
      // Pop to first route and apply preset
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      _alertsViewModel.applyPreset(widget.initialPreset!);
    }
  }

  @override
  void dispose() {
    _alertsViewModel.dispose();
    super.dispose();
  }

  void openAlertDetail(String alertId) async {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    final result = await _navigatorKey.currentState?.pushNamed(
      '/alert-detail',
      arguments: alertId,
    );
    if (result is Alert && mounted) {
      _alertsViewModel.applyUpdatedAlert(result);
    }
  }

  void showList({AdminAlertListPreset preset = AdminAlertListPreset.all}) {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _alertsViewModel.applyPreset(preset);
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
              value: _alertsViewModel,
              child: const AlertsScreen(),
            );
            break;

          case '/alert-detail':
            final alertId = settings.arguments as String;
            builder = (ctx) => ChangeNotifierProvider(
              create: (_) => AlertDetailViewModel(
                alertId: alertId,
                alertRepository: context.read<AlertRepository>(),
                stationRepository: context.read<StationRepository>(),
                sessionController: context.read<AppSessionController>(),
                activeFacilityController: context
                    .read<ActiveFacilityController>(),
              ),
              child: const AlertDetailScreen(),
            );
            break;

          case '/station-detail':
            final stationId = settings.arguments as String;
            builder = (ctx) => ChangeNotifierProvider(
              create: (_) => StationDetailViewModel(
                stationId: stationId,
                stationRepository: context.read<StationRepository>(),
              )..load(),
              child: StationDetailScreen(stationId: stationId),
            );
            break;

          default:
            builder = (ctx) => Scaffold(
              appBar: AppBar(title: const Text('Unknown Route')),
              body: Center(
                child: Text('No route defined for ${settings.name}'),
              ),
            );
        }

        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}
