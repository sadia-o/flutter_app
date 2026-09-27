import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baitguard/domain/models/access_request.dart';
import 'package:baitguard/domain/models/access_request_record.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/domain/repositories/access_request_repository.dart';
import 'package:baitguard/domain/repositories/auth_repository.dart';
import 'package:baitguard/features/authentication/views/login_screen.dart';
import 'package:baitguard/features/authentication/views/request_access_screen.dart';
import 'package:baitguard/features/authentication/view_models/login_view_model.dart';
import 'package:baitguard/features/authentication/view_models/request_access_view_model.dart';
import 'package:baitguard/features/authentication/views/request_submitted_screen.dart';
import 'package:baitguard/app/navigation/route_names.dart';
import 'package:baitguard/core/widgets/primary_button.dart';
import 'package:baitguard/app/state/app_session_controller.dart';
import 'package:baitguard/domain/models/authenticated_identity.dart';
import 'package:baitguard/domain/models/app_user.dart';
import 'package:baitguard/domain/repositories/user_repository.dart';
import 'package:baitguard/domain/repositories/login_preferences_repository.dart';
import 'package:baitguard/data/repositories/mock/in_memory_login_preferences_repository.dart';

class MockTestAccessRequestRepository implements AccessRequestRepository {
  bool requestAccessCalled = false;
  AccessRequest? lastRequest;

  @override
  Future<void> submitRequest(AccessRequest request) async {
    requestAccessCalled = true;
    lastRequest = request;
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> approveRequest({
    required String requestId,
    required String reviewerUid,
    required UserRole assignedRole,
    required List<String> assignedFacilityIds,
  }) => throw UnsupportedError('Not used');

  @override
  Future<void> rejectRequest({
    required String requestId,
    required String reviewerUid,
    required String rejectionReason,
  }) => throw UnsupportedError('Not used');

  @override
  Future<List<AccessRequestRecord>> getPendingRequests({
    String? siteId,
  }) async => [];
}

class DummyAuthRepository extends AuthRepository {
  @override
  Stream<AuthenticatedIdentity?> authStateChanges() => const Stream.empty();

  @override
  Future<AuthenticatedIdentity?> getCurrentIdentity() async => null;

  @override
  Future<AuthenticatedIdentity> signIn(String email, String password) async =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}
}

class DummyUserRepository implements UserRepository {
  @override
  Future<AppUser> updateManagedUserAccess(dynamic request) =>
      throw UnimplementedError();
  @override
  Future<AppUser?> getUserById(String id) async => null;

  @override
  Future<List<AppUser>> getUsers() async => const [];

  @override
  Future<AppUser> updateUser(AppUser user) async => user;

  @override
  Future<AppUser> updateOwnProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required String department,
    required String phone,
    required String bio,
  }) => throw UnimplementedError();
}

void main() {
  Widget buildTestApp(MockTestAccessRequestRepository mockRepo) {
    return MultiProvider(
      providers: [
        Provider<AccessRequestRepository>.value(value: mockRepo),
        Provider<AuthRepository>.value(value: DummyAuthRepository()),
        Provider<UserRepository>.value(value: DummyUserRepository()),
        Provider<LoginPreferencesRepository>.value(
          value: InMemoryLoginPreferencesRepository(),
        ),
        ChangeNotifierProvider(create: (_) => AppSessionController()),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == RouteNames.login) {
            return MaterialPageRoute(
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
          if (settings.name == RouteNames.requestAccess) {
            return MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => RequestAccessViewModel(
                  context.read<AccessRequestRepository>(),
                ),
                child: const RequestAccessScreen(),
              ),
            );
          }
          if (settings.name == RouteNames.requestSubmitted) {
            return MaterialPageRoute(
              builder: (context) => const RequestSubmittedScreen(),
            );
          }
          return null;
        },
        initialRoute: RouteNames.login,
      ),
    );
  }

  Widget buildRequestOnly(MockTestAccessRequestRepository mockRepo) {
    return Provider<AccessRequestRepository>.value(
      value: mockRepo,
      child: MaterialApp(
        home: ChangeNotifierProvider(
          create: (context) =>
              RequestAccessViewModel(context.read<AccessRequestRepository>()),
          child: const RequestAccessScreen(),
        ),
      ),
    );
  }

  testWidgets('Navigation and Request Access form behavior', (
    WidgetTester tester,
  ) async {
    final mockRepo = MockTestAccessRequestRepository();

    await tester.pumpWidget(buildTestApp(mockRepo));
    await tester.pumpAndSettle();

    // 1. Navigate from Login to Request Access
    await tester.ensureVisible(find.text('Contact Administrator'));
    await tester.tap(find.text('Contact Administrator'));
    await tester.pumpAndSettle();

    expect(find.byType(RequestAccessScreen), findsOneWidget);

    // 2. Empty submission shows inline errors for required fields
    await tester.ensureVisible(find.text('Send Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Request'));
    await tester.pump(); // Pump for validation state

    expect(find.text('Full name is required.'), findsOneWidget);
    expect(find.text('Company email is required.'), findsOneWidget);
    expect(find.text('Company or organisation is required.'), findsOneWidget);
    expect(find.text('Phone number is required.'), findsOneWidget);

    // 3. Fill invalid email and phone
    await tester.enterText(find.byType(TextFormField).at(0), 'John Smith');
    await tester.enterText(find.byType(TextFormField).at(1), 'bademail');
    await tester.enterText(find.byType(TextFormField).at(2), 'Acme Corp');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      '123',
    ); // Too short

    await tester.ensureVisible(find.text('Send Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Request'));
    await tester.pump();

    expect(find.text('Enter a valid company email.'), findsOneWidget);
    expect(find.text('Enter a valid phone number.'), findsOneWidget);

    // 4. Fill valid required fields, leave optional empty
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'john@company.com',
    );
    await tester.enterText(find.byType(TextFormField).at(3), '555-019-9999');

    await tester.ensureVisible(find.text('Send Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Request'));
    await tester.pump(); // Start loading

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the mock request to complete
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // 5. Verify repository was called correctly
    expect(mockRepo.requestAccessCalled, isTrue);
    expect(mockRepo.lastRequest?.fullName, 'John Smith');
    expect(mockRepo.lastRequest?.email, 'john@company.com');
    expect(mockRepo.lastRequest?.department, isEmpty);
    expect(mockRepo.lastRequest?.message, isEmpty);

    // 6. Verify navigation occurred instead of toast
    expect(find.text('Request submitted successfully.'), findsNothing);
    expect(find.byType(RequestSubmittedScreen), findsOneWidget);
    expect(find.byType(RequestAccessScreen), findsNothing);

    // 7. Ensure Back to Login button returns to Login
    final button = find.widgetWithText(PrimaryButton, 'Back to Login');
    await tester.dragUntilVisible(
      button,
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RequestSubmittedScreen), findsNothing);
  });

  testWidgets('Android Back and repeated open-close are lifecycle safe', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp(MockTestAccessRequestRepository()));
    await tester.pumpAndSettle();

    for (var index = 0; index < 2; index++) {
      await tester.ensureVisible(find.text('Contact Administrator'));
      await tester.tap(find.text('Contact Administrator'));
      await tester.pumpAndSettle();
      expect(find.byType(RequestAccessScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('small keyboard viewport remains scrollable without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildRequestOnly(MockTestAccessRequestRepository()),
    );
    await tester.pumpAndSettle();

    final emailField = find.byType(TextFormField).at(1);
    await tester.ensureVisible(emailField);
    await tester.tap(emailField);
    await tester.showKeyboard(emailField);
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
