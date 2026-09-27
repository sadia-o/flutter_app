import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../view_models/change_password_view_model.dart';
import 'widgets/settings_preference_scaffold.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final TextEditingController _currentController;
  late final TextEditingController _newController;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<ChangePasswordViewModel>();
    _currentController = TextEditingController()
      ..addListener(
        () => viewModel.updateCurrentPassword(_currentController.text),
      );
    _newController = TextEditingController()
      ..addListener(() => viewModel.updateNewPassword(_newController.text));
    _confirmController = TextEditingController()
      ..addListener(
        () => viewModel.updateConfirmPassword(_confirmController.text),
      );
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChangePasswordViewModel>(
      builder: (context, viewModel, _) {
        return SettingsPreferenceScaffold(
          title: 'Change Password',
          subtitle: 'Keep your telemetry access secure',
          sectionLabel: 'PASSWORD SECURITY',
          saveLabel: 'Update Password',
          isSaving: viewModel.isSaving,
          onSave: () => _submit(context, viewModel),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _passwordField(
                key: const Key('currentPasswordField'),
                label: 'Current Password',
                hint: 'Enter current password',
                controller: _currentController,
                visible: viewModel.showCurrentPassword,
                onToggle: viewModel.toggleCurrentPasswordVisibility,
                enabled: !viewModel.isSaving,
              ),
              const SizedBox(height: AppSpacing.md),
              _passwordField(
                key: const Key('newPasswordField'),
                label: 'New Password',
                hint: 'At least 8 characters',
                controller: _newController,
                visible: viewModel.showNewPassword,
                onToggle: viewModel.toggleNewPasswordVisibility,
                enabled: !viewModel.isSaving,
              ),
              const SizedBox(height: AppSpacing.md),
              _strengthIndicator(viewModel),
              const SizedBox(height: AppSpacing.md),
              _passwordField(
                key: const Key('confirmPasswordField'),
                label: 'Confirm New Password',
                hint: 'Confirm your new password',
                controller: _confirmController,
                visible: viewModel.showConfirmPassword,
                onToggle: viewModel.toggleConfirmPasswordVisibility,
                enabled: !viewModel.isSaving,
              ),
              const SizedBox(height: AppSpacing.md),
              _requirementsCard(viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _passwordField({
    required Key key,
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.manropeSemiBold.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: key,
          controller: controller,
          enabled: enabled,
          obscureText: !visible,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: IconButton(
              key: ValueKey('${label}Visibility'),
              onPressed: onToggle,
              icon: Icon(
                visible ? Icons.visibility_off_outlined : Icons.visibility,
                color: AppColors.textTertiary,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _strengthIndicator(ChangePasswordViewModel viewModel) {
    final color = switch (viewModel.strength) {
      PasswordStrength.weak => AppColors.criticalRed,
      PasswordStrength.medium => AppColors.warningAmber,
      PasswordStrength.strong => AppColors.successGreen,
    };
    final label = switch (viewModel.strength) {
      PasswordStrength.weak => 'Weak',
      PasswordStrength.medium => 'Medium',
      PasswordStrength.strong => 'Strong',
    };
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength:',
              style: AppTypography.manropeRegular.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              label,
              style: AppTypography.manropeSemiBold.copyWith(
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: viewModel.strengthProgress,
          color: color,
          backgroundColor: AppColors.divider,
          minHeight: 8,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ],
    );
  }

  Widget _requirementsCard(ChangePasswordViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SECURITY REQUIREMENTS',
            style: AppTypography.manropeBold.copyWith(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _requirement(
            'At least 8 characters long',
            viewModel.hasMinimumLength,
          ),
          _requirement(
            'At least one uppercase letter (A-Z)',
            viewModel.hasUppercase,
          ),
          _requirement(
            'At least one numerical digit (0-9)',
            viewModel.hasNumber,
          ),
          _requirement(
            'At least one special character (!@#\$%)',
            viewModel.hasSpecialCharacter,
          ),
        ],
      ),
    );
  }

  Widget _requirement(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            met ? Icons.check : Icons.circle_outlined,
            size: 17,
            color: met ? AppColors.successGreen : AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.manropeRegular.copyWith(
                fontSize: 13,
                color: met ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    ChangePasswordViewModel viewModel,
  ) async {
    final success = await viewModel.submit();
    if (!context.mounted) return;
    if (!success) {
      AppTopToast.show(
        context,
        viewModel.errorMessage ?? 'Unable to update password.',
      );
      return;
    }
    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
    Navigator.of(context).pop('Password updated successfully');
  }
}
