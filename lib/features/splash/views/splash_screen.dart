import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../view_models/splash_view_model.dart';
import '../widgets/baitguard_logo_mark.dart';
import '../widgets/splash_background.dart';
import '../widgets/decorative_circles.dart';
import '../../onboarding/views/welcome_screen.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../app/navigation/authenticated_destination_resolver.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SplashViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    // Initialize timing logic in ViewModel post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<SplashViewModel>();
      _viewModel = viewModel;
      viewModel.initialize(const Duration(milliseconds: 2200));
      viewModel.addListener(_onSplashComplete);
    });
  }

  void _onSplashComplete() {
    if (!mounted) return;
    final viewModel = context.read<SplashViewModel>();

    if (viewModel.isCompleted) {
      viewModel.removeListener(_onSplashComplete);
      final currentUser = context.read<AppSessionController>().currentUser;
      if (currentUser == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: RouteNames.welcome),
            builder: (_) => const WelcomeScreen(),
          ),
        );
        return;
      }
      final destination = AuthenticatedDestinationResolver.resolve(
        currentUser.role,
      );
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(destination, (route) => false);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onSplashComplete);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.splashBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Reusable background with navy color, grid, and glows
            const SplashBackground(),

            // 2. Floating decorative circles
            const DecorativeCircles(),

            // 3. Main Content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Logo
                    const BaitGaurdLogoMark(size: 70.0),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Smart BaitGuard',
                      style: AppTypography.manropeExtraBold.copyWith(
                        color: Colors.white,
                        fontSize: 31,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      'AI-POWERED RODENT MONITORING',
                      style: AppTypography.manropeMedium.copyWith(
                        color: AppColors.textTertiary.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        letterSpacing: 2.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(flex: 4),

                    // Footer
                    Text(
                      'POWERED BY SMART IOT SYSTEMS',
                      style: AppTypography.manropeMedium.copyWith(
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: 9.5,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
