import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../dashboard/view_models/admin_dashboard_view_model.dart';
import '../../dashboard/views/admin_dashboard_screen.dart';
import '../../stations/navigation/stations_flow_navigator.dart';
import '../../reports/navigation/reports_flow_navigator.dart';
import '../models/admin_alert_list_preset.dart';
import '../widgets/authenticated_bottom_navigation.dart';
import '../../alerts/navigation/alerts_flow_navigator.dart';
import '../../../app/navigation/route_names.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/access_request_repository.dart';
import '../../admin/view_models/pending_requests_view_model.dart';
import '../../admin/views/pending_requests_screen.dart';
import '../../admin/views/approve_request_screen.dart';
import '../../admin/view_models/review_access_request_view_model.dart';
import '../../../domain/models/access_request_record.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../admin/view_models/system_management_view_model.dart';
import '../../admin/views/system_management_screen.dart';
import '../../admin/views/add_user_screen.dart';
import '../../admin/view_models/add_user_view_model.dart';
import '../../../domain/repositories/admin_invitation_repository.dart';
import '../../admin/view_models/user_management_view_model.dart';
import '../../admin/view_models/user_details_view_model.dart';
import '../../admin/views/user_management_screen.dart';
import '../../admin/views/user_details_screen.dart';
import '../../admin/view_models/manage_user_view_model.dart';
import '../../admin/views/manage_user_screen.dart';

class AdminAppShell extends StatefulWidget {
  const AdminAppShell({super.key});

  @override
  State<AdminAppShell> createState() => _AdminAppShellState();
}

class _AdminAppShellState extends State<AdminAppShell> {
  int _currentIndex = 0;
  AdminAlertListPreset _alertPreset = AdminAlertListPreset.all;
  final GlobalKey<AlertsFlowNavigatorState> _alertsNavigatorKey =
      GlobalKey<AlertsFlowNavigatorState>();
  final GlobalKey<StationsFlowNavigatorState> _stationsNavigatorKey =
      GlobalKey<StationsFlowNavigatorState>();
  final GlobalKey<NavigatorState> _dashboardNavigatorKey =
      GlobalKey<NavigatorState>();

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      if (index == 2) {
        _alertsNavigatorKey.currentState?.showList(
          preset: AdminAlertListPreset.all,
        );
      }
      return;
    }
    setState(() {
      _currentIndex = index;
      if (index == 2) {
        // If they manually tapped the Alerts tab, use the default 'all' preset.
        _alertPreset = AdminAlertListPreset.all;
      }
    });
  }

  void switchTab(
    int index, {
    AdminAlertListPreset preset = AdminAlertListPreset.all,
  }) {
    if (_currentIndex == index && _alertPreset == preset) return;
    setState(() {
      _currentIndex = index;
      if (index == 2) {
        _alertPreset = preset;
      }
    });
    // Need a tiny delay for navigator to be built if it was offstage or not initialized
    if (index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _alertsNavigatorKey.currentState?.showList(preset: preset);
      });
    }
  }

  void openAlertDetail(String alertId) {
    setState(() {
      _currentIndex = 2;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alertsNavigatorKey.currentState?.openAlertDetail(alertId);
    });
  }

  Widget _buildDashboardFlow() {
    return NavigatorPopHandler<void>(
      enabled: _currentIndex == 0,
      onPopWithResult: (_) => _dashboardNavigatorKey.currentState?.maybePop(),
      child: Navigator(
        key: _dashboardNavigatorKey,
        initialRoute: RouteNames.adminDashboard,
        onGenerateRoute: (settings) {
          if (settings.name == RouteNames.pendingRequests) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) {
                final user = context.read<AppSessionController>().currentUser;
                if (user == null ||
                    user.role != UserRole.admin ||
                    !user.isActive) {
                  return const PendingRequestsAccessDeniedScreen();
                }
                return ChangeNotifierProvider(
                  create: (_) => PendingRequestsViewModel(
                    repository: context.read<AccessRequestRepository>(),
                  )..load(),
                  child: PendingRequestsScreen(
                    onApproveRequest: (request) async {
                      return _dashboardNavigatorKey.currentState
                          ?.pushNamed<String>(
                            RouteNames.approveRequest,
                            arguments: request,
                          );
                    },
                    onRequestReviewed: (request) => context
                        .read<AdminDashboardViewModel>()
                        .pendingRequestReviewed(request.submittedAt),
                  ),
                );
              },
            );
          }
          if (settings.name == RouteNames.approveRequest) {
            final request = settings.arguments;
            return MaterialPageRoute<String>(
              settings: settings,
              builder: (context) {
                if (request is! AccessRequestRecord) {
                  return const PendingRequestsAccessDeniedScreen();
                }
                final reviewer = context
                    .read<AppSessionController>()
                    .currentUser;
                if (reviewer == null ||
                    reviewer.role != UserRole.admin ||
                    !reviewer.isActive) {
                  return const PendingRequestsAccessDeniedScreen();
                }
                return ChangeNotifierProvider(
                  create: (_) => ReviewAccessRequestViewModel(
                    request: request,
                    reviewer: reviewer,
                    accessRequestRepository: context
                        .read<AccessRequestRepository>(),
                    settingsRepository: context.read<SettingsRepository>(),
                  ),
                  child: const ApproveRequestScreen(),
                );
              },
            );
          }
          if (settings.name == RouteNames.systemManagement) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) {
                final user = context.read<AppSessionController>().currentUser;
                if (user == null ||
                    user.role != UserRole.admin ||
                    !user.isActive) {
                  return const SystemManagementAccessDeniedScreen();
                }
                return ChangeNotifierProvider(
                  create: (_) => SystemManagementViewModel(
                    userRepository: context.read<UserRepository>(),
                    settingsRepository: context.read<SettingsRepository>(),
                    sessionController: context.read<AppSessionController>(),
                  )..load(),
                  child: SystemManagementScreen(
                    onOpenUsers: () => _dashboardNavigatorKey.currentState
                        ?.pushNamed(RouteNames.userManagement),
                    onAddUser: () async {
                      final navigator = _dashboardNavigatorKey.currentState;
                      if (navigator == null) return null;
                      return navigator.pushNamed<bool>(RouteNames.addUser);
                    },
                  ),
                );
              },
            );
          }
          if (settings.name == RouteNames.addUser) {
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (context) {
                final user = context.read<AppSessionController>().currentUser;
                if (user == null ||
                    user.role != UserRole.admin ||
                    !user.isActive) {
                  return const SystemManagementAccessDeniedScreen();
                }
                return ChangeNotifierProvider(
                  create: (_) => AddUserViewModel(
                    invitationRepository: context
                        .read<AdminInvitationRepository>(),
                    userRepository: context.read<UserRepository>(),
                    settingsRepository: context.read<SettingsRepository>(),
                    sessionController: context.read<AppSessionController>(),
                  ),
                  child: const AddUserScreen(),
                );
              },
            );
          }
          if (settings.name == RouteNames.userManagement) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) {
                final user = context.read<AppSessionController>().currentUser;
                if (user == null ||
                    user.role != UserRole.admin ||
                    !user.isActive) {
                  return const UserManagementAccessDeniedScreen();
                }
                return ChangeNotifierProvider(
                  create: (_) => UserManagementViewModel(
                    userRepository: context.read<UserRepository>(),
                    sessionController: context.read<AppSessionController>(),
                  )..load(),
                  child: UserManagementScreen(
                    onUserTap: (userId) async =>
                        _dashboardNavigatorKey.currentState?.pushNamed<bool>(
                          RouteNames.userDetails,
                          arguments: userId,
                        ),
                    onAddUser: () async {
                      final navigator = _dashboardNavigatorKey.currentState;
                      if (navigator == null) return null;
                      return navigator.pushNamed<bool>(RouteNames.addUser);
                    },
                  ),
                );
              },
            );
          }
          if (settings.name == RouteNames.userDetails) {
            final userId = settings.arguments;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (context) {
                final reviewer = context
                    .read<AppSessionController>()
                    .currentUser;
                if (reviewer == null ||
                    reviewer.role != UserRole.admin ||
                    !reviewer.isActive ||
                    userId is! String ||
                    userId.trim().isEmpty) {
                  return const UserManagementAccessDeniedScreen();
                }
                return ChangeNotifierProvider(
                  create: (_) => UserDetailsViewModel(
                    userId: userId,
                    userRepository: context.read<UserRepository>(),
                    settingsRepository: context.read<SettingsRepository>(),
                    sessionController: context.read<AppSessionController>(),
                  )..load(),
                  child: UserDetailsScreen(
                    onManageUser: (targetId) async =>
                        _dashboardNavigatorKey.currentState?.pushNamed<bool>(
                          RouteNames.manageUser,
                          arguments: targetId,
                        ),
                  ),
                );
              },
            );
          }
          if (settings.name == RouteNames.manageUser) {
            final targetUserId = settings.arguments;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (context) {
                final reviewer = context
                    .read<AppSessionController>()
                    .currentUser;
                if (reviewer == null ||
                    reviewer.role != UserRole.admin ||
                    !reviewer.isActive ||
                    targetUserId is! String ||
                    targetUserId.trim().isEmpty ||
                    reviewer.id == targetUserId) {
                  return const UserManagementAccessDeniedScreen();
                }
                return ChangeNotifierProvider(
                  create: (_) => ManageUserViewModel(
                    targetUserId: targetUserId,
                    userRepository: context.read<UserRepository>(),
                    settingsRepository: context.read<SettingsRepository>(),
                    sessionController: context.read<AppSessionController>(),
                  )..load(),
                  child: const ManageUserScreen(),
                );
              },
            );
          }
          return MaterialPageRoute(
            settings: const RouteSettings(name: RouteNames.adminDashboard),
            builder: (_) => AdminDashboardScreen(
              onSelectTab: switchTab,
              onAlertTap: openAlertDetail,
              onReviewRequests: () => _dashboardNavigatorKey.currentState
                  ?.pushNamed(RouteNames.pendingRequests),
              onManageSystem: () => _dashboardNavigatorKey.currentState
                  ?.pushNamed(RouteNames.systemManagement),
              onUsers: () => _dashboardNavigatorKey.currentState?.pushNamed(
                RouteNames.userManagement,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadAlertCount = context.select<AdminDashboardViewModel, int>(
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
            _buildDashboardFlow(),
            // Screen 08 - Stations nested flow
            StationsFlowNavigator(key: _stationsNavigatorKey),
            // Screen 09 - Alerts nested flow
            AlertsFlowNavigator(
              key: _alertsNavigatorKey,
              initialPreset: _alertPreset,
            ),
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
