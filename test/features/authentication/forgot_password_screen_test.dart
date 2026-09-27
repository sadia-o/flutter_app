import 'dart:async';

import 'package:baitguard/app/navigation/route_names.dart';
import 'package:baitguard/domain/models/auth_failure.dart';
import 'package:baitguard/domain/models/authenticated_identity.dart';
import 'package:baitguard/domain/repositories/auth_repository.dart';
import 'package:baitguard/features/authentication/view_models/forgot_password_view_model.dart';
import 'package:baitguard/features/authentication/views/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _WidgetAuthRepository extends AuthRepository {
  int resetCalls = 0;
  AuthFailure? failure;
  Completer<void>? completer;

  @override
  Stream<AuthenticatedIdentity?> authStateChanges() => const Stream.empty();

  @override
  Future<AuthenticatedIdentity?> getCurrentIdentity() async => null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCalls++;
    if (failure != null) throw failure!;
    if (completer != null) await completer!.future;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<AuthenticatedIdentity> signIn(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

Widget _testApp(_WidgetAuthRepository repository) {
  return Provider<AuthRepository>.value(
    value: repository,
    child: MaterialApp(
      initialRoute: RouteNames.login,
      routes: {
        RouteNames.login: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteNames.forgotPassword),
              child: const Text('Forgot Password?'),
            ),
          ),
        ),
        RouteNames.forgotPassword: (context) => ChangeNotifierProvider(
          create: (_) =>
              ForgotPasswordViewModel(context.read<AuthRepository>()),
          child: const ForgotPasswordScreen(),
        ),
      },
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  _WidgetAuthRepository repository,
) async {
  await tester.pumpWidget(_testApp(repository));
  await tester.tap(find.text('Forgot Password?'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens from Login and Back returns safely', (tester) async {
    final repository = _WidgetAuthRepository();
    await _open(tester, repository);

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('successful send shows privacy-safe confirmation', (
    tester,
  ) async {
    final repository = _WidgetAuthRepository();
    await _open(tester, repository);

    await tester.enterText(find.byType(TextFormField), 'person@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(repository.resetCalls, 1);
    expect(find.text('Check your email'), findsOneWidget);
    expect(
      find.text(
        'If an account exists for this email, password reset '
        'instructions have been sent.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('registered'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading prevents duplicate send and keeps button dimensions', (
    tester,
  ) async {
    final repository = _WidgetAuthRepository()..completer = Completer<void>();
    await _open(tester, repository);

    await tester.enterText(find.byType(TextFormField), 'person@example.com');
    final sizeBefore = tester.getSize(find.byType(ElevatedButton));
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(repository.resetCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.getSize(find.byType(ElevatedButton)), sizeBefore);

    repository.completer!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('network failure preserves email and shows safe feedback', (
    tester,
  ) async {
    final repository = _WidgetAuthRepository()
      ..failure = const AuthFailure(AuthFailureType.network);
    await _open(tester, repository);

    await tester.enterText(find.byType(TextFormField), 'person@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();

    expect(find.text('person@example.com'), findsOneWidget);
    expect(find.textContaining('Unable to connect'), findsOneWidget);
    expect(find.textContaining('Firebase'), findsNothing);

    // Allow AppTopToast's intentional dismissal timer and animation to finish.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('system Back and repeated open-close do not throw', (
    tester,
  ) async {
    final repository = _WidgetAuthRepository();
    await tester.pumpWidget(_testApp(repository));

    for (var index = 0; index < 2; index++) {
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('small keyboard viewport scrolls without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _WidgetAuthRepository();
    await _open(tester, repository);
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.tap(find.byType(TextFormField));
    await tester.showKeyboard(find.byType(TextFormField));
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
