import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/navigation/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../widgets/welcome_illustration.dart';
import '../widgets/feature_chip.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F5FF), // Very light blue background
        body: Stack(
          children: [
            // Soft pale blue gradient glow at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFEAF1FF), Color(0xFFF0F5FF)],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // Upper illustration area
                Expanded(
                  flex: 4,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: const WelcomeIllustration(),
                    ),
                  ),
                ),

                // Lower white content panel
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                          AppRadii.xl * 2,
                        ), // Large rounded corners
                        topRight: Radius.circular(AppRadii.xl * 2),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                          vertical: AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            // Heading
                            Text(
                              'Welcome to\nSmart BaitGuard',
                              textAlign: TextAlign.center,
                              style: AppTypography.manropeExtraBold.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Description
                            Text(
                              'Monitor smart bait stations in real time, receive\ninstant alerts, analyse rodent activity, and manage\nfacilities from anywhere with AI-powered monitoring.',
                              textAlign: TextAlign.center,
                              style: AppTypography.manropeRegular.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Feature Chips
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: const [
                                FeatureChip(label: 'Real-time alerts'),
                                FeatureChip(label: 'AI detection'),
                                FeatureChip(label: 'Cloud sync'),
                                FeatureChip(label: 'Multi-site'),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Primary Log In Button
                            PrimaryButton(
                              text: 'Log In',
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(RouteNames.login);
                              },
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Learn More Secondary Action
                            TextButton(
                              onPressed: () {
                                AppTopToast.show(
                                  context,
                                  'More product information will be available soon.',
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                textStyle: AppTypography.manropeMedium.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Learn More'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
