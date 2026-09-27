import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:baitguard/app/app.dart';
import 'package:baitguard/features/authentication/views/login_screen.dart';
import 'package:baitguard/features/authentication/views/forgot_password_screen.dart';
import 'package:baitguard/features/splash/widgets/baitguard_logo_mark.dart';
import 'package:baitguard/features/navigation/views/admin_app_shell.dart';

void main() {
  testWidgets('Login Screen interactions and flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BaitGuardApp());

    // Skip splash
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(seconds: 1));

    // Tap Welcome "Log In"
    await tester.tap(find.text('Log In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // 2. Login heading renders
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);

    // 3. Empty submission shows inline errors
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pump();
    expect(find.text('Email address is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);

    // 4. Invalid email shows an email error
    await tester.enterText(find.byType(TextFormField).first, 'bademail');
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    // 5. Short password shows a password error
    await tester.enterText(find.byType(TextFormField).last, '12345');
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pump();
    expect(
      find.text('Password must contain at least 6 characters.'),
      findsOneWidget,
    );

    // 6. Password visibility toggles
    await tester.ensureVisible(find.byIcon(Icons.visibility));
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    // 7. Remember-me checkbox toggles
    await tester.ensureVisible(find.text('Remember me'));
    await tester.tap(find.text('Remember me'));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);

    // 13. Forgot Password opens its standalone route and returns safely.
    await tester.ensureVisible(find.text('Forgot Password?'));
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // 8. Valid credentials call the mock repository
    await tester.enterText(
      find.byType(TextFormField).first,
      'admin@baitguard.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'admin123');

    // 9. Loading state prevents duplicate submission
    await tester.ensureVisible(find.text('Log In'));
    await tester.tap(find.text('Log In'));
    await tester.pump(); // Start loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for mock login to complete (500ms in MockAuthRepository + 200ms in MockUserRepository)
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    // 10. Successful login opens the admin app shell for admin role
    expect(find.byType(AdminAppShell), findsOneWidget);

    // 11. Authentication screens are removed from the stack after success
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(BaitGaurdLogoMark), findsNothing);

    // Clear any timers or animations (e.g. from the newly mounted AdminAppShell and its tabs)
    await tester.pumpAndSettle();
  });
}
