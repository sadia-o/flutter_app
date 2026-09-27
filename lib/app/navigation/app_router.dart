import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'route_names.dart';
import '../../legacy/legacy_main_navigation.dart';
import '../../features/onboarding/views/welcome_screen.dart';
import '../../features/authentication/views/login_screen.dart';
import '../../features/authentication/view_models/login_view_model.dart';
import '../../features/authentication/views/forgot_password_screen.dart';
import '../../features/authentication/view_models/forgot_password_view_model.dart';
import '../../features/authentication/views/activate_account_screen.dart';
import '../../features/authentication/view_models/activate_account_view_model.dart';
import '../../features/authentication/views/request_access_screen.dart';
import '../../features/authentication/views/request_submitted_screen.dart';
import '../../features/authentication/view_models/request_access_view_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/access_request_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/station_repository.dart';
import '../../data/repositories/firebase/realtime_station_data_source.dart';
import '../../app/state/app_session_controller.dart';
import '../../app/state/active_facility_controller.dart';
import '../../features/navigation/views/user_app_shell.dart';
import '../../features/dashboard/view_models/user_dashboard_view_model.dart';
import '../../features/navigation/views/admin_app_shell.dart';
import '../../features/dashboard/view_models/admin_dashboard_view_model.dart';
import '../../features/stations/view_models/stations_view_model.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/settings/views/edit_profile_screen.dart';
import '../../features/settings/view_models/settings_view_model.dart';
import '../../features/settings/view_models/edit_profile_view_model.dart';
import '../../features/settings/view_models/settings_preferences_view_model.dart';
import '../../features/settings/views/default_view_screen.dart';
import '../../features/settings/views/default_facility_screen.dart';
import '../../features/settings/views/default_alert_filter_screen.dart';
import '../../features/settings/views/change_password_screen.dart';
import '../../features/settings/views/contact_admin_screen.dart';
import '../../features/settings/view_models/change_password_view_model.dart';
import '../../features/settings/view_models/contact_admin_view_model.dart';
import '../../features/settings/views/privacy_policy_screen.dart';
import '../../features/settings/views/terms_conditions_screen.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/login_preferences_repository.dart';
import '../../domain/repositories/account_activation_repository.dart';
import '../../features/admin/views/pending_requests_screen.dart';
import '../../features/admin/view_models/pending_requests_view_model.dart';
import '../../domain/models/user_role.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == RouteNames.legacy) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const MainNavigation(),
      );
    }

    if (settings.name == RouteNames.welcome) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const WelcomeScreen(),
      );
    }

    if (settings.name == RouteNames.login) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) => LoginViewModel(
            context.read<AuthRepository>(),
            context.read<UserRepository>(),
            context.read<AppSessionController>(),
            context.read<LoginPreferencesRepository>(),
          ),
          child: const LoginScreen(),
        ),
      );
    }

    if (settings.name == RouteNames.forgotPassword) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) =>
              ForgotPasswordViewModel(context.read<AuthRepository>()),
          child: const ForgotPasswordScreen(),
        ),
      );
    }

    if (settings.name == RouteNames.activateAccount) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) => ActivateAccountViewModel(
            authRepository: context.read<AuthRepository>(),
            activationRepository: context.read<AccountActivationRepository>(),
            sessionController: context.read<AppSessionController>(),
            userRepository: context.read<UserRepository>(),
          ),
          child: const ActivateAccountScreen(),
        ),
      );
    }

    if (settings.name == RouteNames.requestAccess) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) =>
              RequestAccessViewModel(context.read<AccessRequestRepository>()),
          child: const RequestAccessScreen(),
        ),
      );
    }

    if (settings.name == RouteNames.requestSubmitted) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const RequestSubmittedScreen(),
      );
    }

    if (settings.name == RouteNames.userDashboard) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) {
          final session = context.read<AppSessionController>();
          final user = session.currentUser;

          // Build the permitted site IDs for this viewer/technician.
          final permittedSiteIds = user?.siteAccessIds ?? const [];

          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ActiveFacilityController>(
                create: (ctx) {
                  final controller = ActiveFacilityController(
                    permittedSiteIds: List<String>.unmodifiable(
                      permittedSiteIds,
                    ),
                  );
                  try {
                    final ds = ctx.read<RealtimeStationDataSource>();
                    ds.bindSessionAndFacility(
                      user: user,
                      facilityId: controller.selectedSiteId,
                    );
                    controller.addListener(() {
                      ds.bindSessionAndFacility(
                        user: session.currentUser,
                        facilityId: controller.selectedSiteId,
                      );
                    });
                  } catch (_) {}
                  return controller;
                },
              ),
              ChangeNotifierProxyProvider<
                ActiveFacilityController,
                UserDashboardViewModel
              >(
                create: (ctx) => UserDashboardViewModel(
                  dashboardRepository: context.read<DashboardRepository>(),
                  sessionController: session,
                  activeFacilityController: ctx
                      .read<ActiveFacilityController>(),
                )..load(),
                update: (context, controller, previous) => previous!,
              ),
              ChangeNotifierProxyProvider<
                ActiveFacilityController,
                StationsViewModel
              >(
                create: (ctx) => StationsViewModel(
                  stationRepository: context.read<StationRepository>(),
                  sessionController: session,
                  activeFacilityController: ctx
                      .read<ActiveFacilityController>(),
                ),
                update: (context, controller, previous) => previous!,
              ),
            ],
            child: const UserAppShell(),
          );
        },
      );
    }

    if (settings.name == RouteNames.adminDashboard) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) {
          final session = context.read<AppSessionController>();
          final user = session.currentUser;
          final permittedSiteIds = user?.siteAccessIds ?? const [];

          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ActiveFacilityController>(
                create: (ctx) {
                  final controller = ActiveFacilityController(
                    permittedSiteIds: List<String>.unmodifiable(
                      permittedSiteIds,
                    ),
                  );
                  try {
                    final ds = ctx.read<RealtimeStationDataSource>();
                    ds.bindSessionAndFacility(
                      user: user,
                      facilityId: controller.selectedSiteId,
                    );
                    controller.addListener(() {
                      ds.bindSessionAndFacility(
                        user: session.currentUser,
                        facilityId: controller.selectedSiteId,
                      );
                    });
                  } catch (_) {}
                  return controller;
                },
              ),
              ChangeNotifierProxyProvider<
                ActiveFacilityController,
                AdminDashboardViewModel
              >(
                create: (ctx) => AdminDashboardViewModel(
                  dashboardRepository: context.read<DashboardRepository>(),
                  accessRequestRepository: context
                      .read<AccessRequestRepository>(),
                  sessionController: session,
                  activeFacilityController: ctx
                      .read<ActiveFacilityController>(),
                )..load(),
                update: (context, controller, previous) => previous!,
              ),
              ChangeNotifierProxyProvider<
                ActiveFacilityController,
                StationsViewModel
              >(
                create: (ctx) => StationsViewModel(
                  stationRepository: context.read<StationRepository>(),
                  sessionController: session,
                  activeFacilityController: ctx
                      .read<ActiveFacilityController>(),
                ),
                update: (context, controller, previous) => previous!,
              ),
            ],
            child: const AdminAppShell(),
          );
        },
      );
    }

    if (settings.name == RouteNames.pendingRequests) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) {
          final user = context.read<AppSessionController>().currentUser;
          if (user == null || user.role != UserRole.admin || !user.isActive) {
            return const PendingRequestsAccessDeniedScreen();
          }
          return ChangeNotifierProvider(
            create: (_) => PendingRequestsViewModel(
              repository: context.read<AccessRequestRepository>(),
            )..load(),
            child: const PendingRequestsScreen(),
          );
        },
      );
    }

    if (settings.name == RouteNames.settings) {
      final activeFacilityController =
          settings.arguments as ActiveFacilityController;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) {
          final session = context.read<AppSessionController>();
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ActiveFacilityController>.value(
                value: activeFacilityController,
              ),
              ChangeNotifierProvider<SettingsViewModel>(
                create: (_) => SettingsViewModel(
                  settingsRepository: context.read<SettingsRepository>(),
                  sessionController: session,
                  activeFacilityController: activeFacilityController,
                ),
              ),
            ],
            child: const SettingsScreen(),
          );
        },
      );
    }

    if (settings.name == RouteNames.editProfile) {
      final assignedFacilityName = settings.arguments as String? ?? 'None';
      // Arguments: the AppSessionController is globally available;
      // UserRepository is globally provided — no extra args needed.
      return MaterialPageRoute(
        settings: settings,
        builder: (context) {
          final session = context.read<AppSessionController>();
          return ChangeNotifierProvider<EditProfileViewModel>(
            create: (_) => EditProfileViewModel(
              userRepository: context.read<UserRepository>(),
              sessionController: session,
              assignedFacilityName: assignedFacilityName,
            ),
            child: const EditProfileScreen(),
          );
        },
      );
    }

    if (settings.name == RouteNames.defaultView ||
        settings.name == RouteNames.defaultFacility ||
        settings.name == RouteNames.defaultAlertFilter) {
      final arguments = settings.arguments as SettingsPreferencesRouteArguments;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) => SettingsPreferencesViewModel(
            repository: context.read<SettingsRepository>(),
            initialSettings: arguments.settings,
            permittedFacilityIds: arguments.permittedFacilityIds,
          ),
          child: settings.name == RouteNames.defaultView
              ? const DefaultViewScreen()
              : settings.name == RouteNames.defaultFacility
              ? const DefaultFacilityScreen()
              : const DefaultAlertFilterScreen(),
        ),
      );
    }

    if (settings.name == RouteNames.changePassword) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) => ChangePasswordViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
          child: const ChangePasswordScreen(),
        ),
      );
    }

    if (settings.name == RouteNames.contactAdministrator) {
      final userId = settings.arguments as String;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ChangeNotifierProvider(
          create: (_) => ContactAdminViewModel(
            repository: context.read<SettingsRepository>(),
            userId: userId,
          ),
          child: const ContactAdminScreen(),
        ),
      );
    }

    if (settings.name == RouteNames.privacyPolicy) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const PrivacyPolicyScreen(),
      );
    }

    if (settings.name == RouteNames.termsConditions) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const TermsConditionsScreen(),
      );
    }

    throw Exception('Unknown route: ${settings.name}');
  }
}
