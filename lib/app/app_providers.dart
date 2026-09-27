import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'state/app_session_controller.dart';
import 'state/auth_session_coordinator.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/access_request_repository.dart';
import '../domain/repositories/admin_invitation_repository.dart';
import '../domain/repositories/station_repository.dart';
import '../domain/repositories/alert_repository.dart';
import '../domain/repositories/report_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/login_preferences_repository.dart';
import '../domain/repositories/account_activation_repository.dart';

import '../data/repositories/mock/mock_baitguard_data_source.dart';
import '../data/repositories/firebase/firebase_auth_repository.dart';
import '../data/repositories/firebase/firestore_user_repository.dart';
import '../data/repositories/firebase/firestore_access_request_repository.dart';
import '../data/repositories/firebase/firestore_account_activation_repository.dart';
import '../data/repositories/mock/mock_auth_repository.dart';
import '../data/repositories/mock/mock_access_request_repository.dart';
import '../data/repositories/mock/mock_account_activation_repository.dart';
import '../data/repositories/mock/mock_station_repository.dart';
import '../data/repositories/mock/mock_alert_repository.dart';
import '../data/repositories/mock/mock_report_repository.dart';
import '../data/repositories/mock/mock_user_repository.dart';
import '../data/repositories/mock/mock_dashboard_repository.dart';
import '../data/repositories/mock/mock_settings_repository.dart';
import '../data/repositories/mock/in_memory_login_preferences_repository.dart';
import '../data/repositories/preferences/shared_preferences_login_repository.dart';

import '../data/repositories/firebase/realtime_station_data_source.dart';
import '../data/repositories/firebase/realtime_station_repository.dart';
import '../data/repositories/firebase/realtime_alert_repository.dart';
import '../data/repositories/firebase/realtime_dashboard_repository.dart';
import '../data/repositories/firebase/realtime_report_repository.dart';

class AppProviders {
  static List<SingleChildWidget> get providers {
    final hasFirebase = Firebase.apps.isNotEmpty;

    return [
      ChangeNotifierProvider<AppSessionController>(
        create: (_) => AppSessionController(),
      ),
      Provider<MockBaitGuardDataSource>(
        create: (_) => MockBaitGuardDataSource.seeded(),
      ),
      if (hasFirebase)
        Provider<RealtimeStationDataSource>(
          create: (ctx) {
            final ds = RealtimeStationDataSource();
            final session = ctx.read<AppSessionController>();
            session.addListener(() {
              final user = session.currentUser;
              if (user == null || !user.isActive) {
                ds.bindSessionAndFacility(user: null, facilityId: null);
              }
            });
            return ds;
          },
          dispose: (_, ds) => ds.dispose(),
        ),
      Provider<AuthRepository>(
        create: (context) => hasFirebase
            ? FirebaseAuthRepository(FirebaseAuth.instance)
            : MockAuthRepository(context.read<MockBaitGuardDataSource>()),
      ),
      Provider<UserRepository>(
        create: (context) => hasFirebase
            ? FirestoreUserRepository(
                FirebaseFirestore.instance,
                FirebaseAuth.instance,
              )
            : MockUserRepository(context.read<MockBaitGuardDataSource>()),
      ),
      Provider<LoginPreferencesRepository>(
        create: (_) => hasFirebase
            ? SharedPreferencesLoginRepository()
            : InMemoryLoginPreferencesRepository(),
      ),
      Provider<AccessRequestRepository>(
        create: (context) => hasFirebase
            ? FirestoreAccessRequestRepository(
                FirebaseFirestore.instance,
                FirebaseAuth.instance,
              )
            : MockAccessRequestRepository(
                context.read<MockBaitGuardDataSource>(),
              ),
      ),
      Provider<AdminInvitationRepository>(
        create: (context) =>
            context.read<AccessRequestRepository>()
                as AdminInvitationRepository,
      ),
      Provider<AccountActivationRepository>(
        create: (context) => hasFirebase
            ? FirestoreAccountActivationRepository(
                FirebaseFirestore.instance,
                FirebaseAuth.instance,
              )
            : MockAccountActivationRepository(
                context.read<MockBaitGuardDataSource>(),
              ),
      ),
      Provider<StationRepository>(
        create: (context) => hasFirebase
            ? RealtimeStationRepository(
                context.read<RealtimeStationDataSource>(),
              )
            : MockStationRepository(context.read<MockBaitGuardDataSource>()),
      ),
      Provider<AlertRepository>(
        create: (context) => hasFirebase
            ? RealtimeAlertRepository(context.read<RealtimeStationDataSource>())
            : MockAlertRepository(context.read<MockBaitGuardDataSource>()),
      ),
      Provider<MockUserRepository>(
        create: (context) =>
            MockUserRepository(context.read<MockBaitGuardDataSource>()),
      ),
      Provider<ReportRepository>(
        create: (context) => hasFirebase
            ? RealtimeReportRepository(
                context.read<RealtimeStationDataSource>(),
              )
            : MockReportRepository(context.read<MockBaitGuardDataSource>()),
      ),
      Provider<DashboardRepository>(
        create: (context) => hasFirebase
            ? RealtimeDashboardRepository(
                context.read<RealtimeStationDataSource>(),
                userRepository: context.read<UserRepository>(),
              )
            : MockDashboardRepository(context.read<MockBaitGuardDataSource>()),
      ),
      Provider<SettingsRepository>(
        create: (context) =>
            MockSettingsRepository(context.read<MockBaitGuardDataSource>()),
      ),
      ChangeNotifierProvider<AuthSessionCoordinator>(
        lazy: false,
        create: (context) => AuthSessionCoordinator(
          authRepository: context.read<AuthRepository>(),
          userRepository: context.read<UserRepository>(),
          sessionController: context.read<AppSessionController>(),
        )..initialize(),
      ),
    ];
  }
}
