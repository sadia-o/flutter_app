import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../splash/widgets/baitguard_logo_mark.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl),
        const BaitGaurdLogoMark(size: 64.0),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Welcome Back',
          style: AppTypography.manropeExtraBold.copyWith(
            fontSize: 22,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sign in to monitor your smart bait stations.',
          style: AppTypography.manropeRegular.copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
