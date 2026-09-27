import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/navigation/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/request_next_steps_card.dart';
import '../widgets/request_success_icon.dart';

class RequestSubmittedScreen extends StatelessWidget {
  const RequestSubmittedScreen({super.key});

  void _onBackToLogin(BuildContext context) {
    Navigator.of(context).popUntil((route) {
      return route.settings.name == RouteNames.login || route.isFirst;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Upper flexible space for responsive positioning
                        const SizedBox(height: AppSpacing.xxl * 1.5),

                        const RequestSuccessIcon(),

                        const SizedBox(height: AppSpacing.xl),

                        Text(
                          'Request Submitted\nSuccessfully',
                          textAlign: TextAlign.center,
                          style: AppTypography.manropeExtraBold.copyWith(
                            fontSize: 24,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        Text(
                          'Thank you for your request. Your system\n'
                          'administrator has received your information and will\n'
                          'review it shortly. You will be notified once your\n'
                          'account has been approved.',
                          textAlign: TextAlign.center,
                          style: AppTypography.manropeRegular.copyWith(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        const RequestNextStepsCard(),

                        // Spacer to push the button towards the bottom
                        const Spacer(),

                        const SizedBox(height: AppSpacing.xl),
                        PrimaryButton(
                          text: 'Back to Login',
                          onPressed: () => _onBackToLogin(context),
                        ),

                        const SizedBox(height: AppSpacing.xxl),
                        SafeArea(
                          top: false,
                          child: const SizedBox(height: AppSpacing.lg),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
