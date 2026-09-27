import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

class RememberMeRow extends StatelessWidget {
  const RememberMeRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onForgotPasswordPressed,
  });

  final bool value;
  final VoidCallback onChanged;
  final VoidCallback onForgotPasswordPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onChanged,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: value ? AppColors.primaryBlue : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: value
                        ? AppColors.primaryBlue
                        : AppColors.borderPrimary,
                    width: 1.5,
                  ),
                ),
                child: value
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Remember me',
                style: AppTypography.manropeMedium.copyWith(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onForgotPasswordPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot Password?',
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 13,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}
