import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/app/app.dart';
import 'package:baitguard/features/splash/widgets/baitguard_logo_mark.dart';
import 'package:baitguard/features/onboarding/views/welcome_screen.dart';
import 'package:baitguard/legacy/legacy_main_navigation.dart';

void main() {
  testWidgets('Splash -> Welcome -> Legacy Flow', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BaitGuardApp());

    // 1. Splash appears first
    expect(find.text('Smart BaitGuard'), findsOneWidget);
    expect(find.text('AI-POWERED RODENT MONITORING'), findsOneWidget);
    expect(find.byType(BaitGaurdLogoMark), findsOneWidget);

    // 2. Splash completion occurs after the configured duration (2.2s)
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(
      const Duration(seconds: 1),
    ); // Let the navigation transition complete

    // 3. Welcome appears after the Splash duration
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // 7. Splash is not left in the navigation stack
    expect(find.byType(BaitGaurdLogoMark), findsNothing);
    expect(
      find.text('AI-POWERED RODENT MONITORING'),
      findsNothing,
    ); // Splash tagline is gone

    // 4. Welcome heading is visible
    expect(find.text('Welcome to\nSmart BaitGuard'), findsOneWidget);

    // 5. Feature-chip text is visible
    expect(find.text('Real-time alerts'), findsOneWidget);
    expect(find.text('AI detection'), findsOneWidget);

    // 6. Legacy dashboard is not initially visible on Welcome
    expect(find.byType(MainNavigation), findsNothing);

    // 7. Advance additional time without tapping anything to prove Welcome does not automatically redirect
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(MainNavigation), findsNothing);

    // 8. Tapping Log In navigates to the Login screen
    final logInButton = find.text('Log In');
    expect(logInButton, findsOneWidget);
    await tester.tap(logInButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // 9. Login screen appears
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
