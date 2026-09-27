import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/authenticated_destination_resolver.dart';
import '../../../app/navigation/route_names.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../core/widgets/primary_button.dart';
import '../view_models/activate_account_view_model.dart';

class ActivateAccountScreen extends StatefulWidget {
  const ActivateAccountScreen({super.key});

  @override
  State<ActivateAccountScreen> createState() => _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends State<ActivateAccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<ActivateAccountViewModel>();
      await viewModel.initialize();
      if (!mounted) return;
      _email.text = viewModel.email;
      _completeNavigation();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<ActivateAccountViewModel>();
    final success = viewModel.stage == ActivateAccountStage.form
        ? await viewModel.submit()
        : await viewModel.checkVerification();
    if (!mounted) return;
    if (success) {
      _password.clear();
      _confirmation.clear();
      _completeNavigation();
    } else if (viewModel.errorMessage != null) {
      AppTopToast.show(context, viewModel.errorMessage!);
    }
  }

  void _completeNavigation() {
    final session = context.read<AppSessionController>();
    final user = session.currentUser;
    if (user == null) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AuthenticatedDestinationResolver.resolve(user.role),
      (_) => false,
    );
  }

  Future<void> _back() async {
    await context.read<ActivateAccountViewModel>().abandon();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ActivateAccountViewModel>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    AppBackButton(onPressed: _back),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Activate Account',
                      style: AppTypography.manropeExtraBold.copyWith(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: viewModel.stage == ActivateAccountStage.form
                        ? _buildForm(viewModel)
                        : _buildVerification(viewModel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ActivateAccountViewModel viewModel) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 54,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Enter the email approved by your administrator and create a secure password.',
            textAlign: TextAlign.center,
            style: AppTypography.manropeRegular.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Approved Email',
            hintText: 'you@company.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            errorText: viewModel.emailError,
            onChanged: viewModel.setEmail,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'New Password',
            hintText: 'Create a secure password',
            controller: _password,
            obscureText: viewModel.obscurePassword,
            autofillHints: const [AutofillHints.newPassword],
            errorText: viewModel.passwordError,
            onChanged: viewModel.setPassword,
            suffixIcon: IconButton(
              onPressed: viewModel.togglePassword,
              icon: Icon(
                viewModel.obscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PasswordRequirements(viewModel: viewModel),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Confirm Password',
            hintText: 'Repeat your password',
            controller: _confirmation,
            obscureText: viewModel.obscureConfirmation,
            errorText: viewModel.confirmationError,
            onChanged: viewModel.setConfirmation,
            suffixIcon: IconButton(
              onPressed: viewModel.toggleConfirmation,
              icon: Icon(
                viewModel.obscureConfirmation
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            text: 'Activate Account',
            isLoading: viewModel.isLoading,
            onPressed: _submit,
          ),
          TextButton(onPressed: _back, child: const Text('Back to Login')),
        ],
      ),
    );
  }

  Widget _buildVerification(ActivateAccountViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: AppColors.primaryBlue,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Verify Your Email',
          textAlign: TextAlign.center,
          style: AppTypography.manropeExtraBold.copyWith(fontSize: 24),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We sent a verification link to your email. Verify your address, then return here to continue.',
          textAlign: TextAlign.center,
          style: AppTypography.manropeRegular.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          text: 'I’ve Verified My Email',
          isLoading: viewModel.isLoading,
          onPressed: _submit,
        ),
        TextButton(
          onPressed: viewModel.isLoading
              ? null
              : () async {
                  final success = await viewModel.resendVerification();
                  if (!mounted) return;
                  AppTopToast.show(
                    context,
                    success
                        ? 'Verification email sent.'
                        : viewModel.errorMessage ??
                              'Unable to resend verification email.',
                  );
                },
          child: const Text('Resend Email'),
        ),
        TextButton(onPressed: _back, child: const Text('Back to Login')),
      ],
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.viewModel});

  final ActivateAccountViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final rules = <(bool, String)>[
      (viewModel.hasMinimumLength, 'At least 8 characters'),
      (viewModel.hasUppercase, 'One uppercase letter'),
      (viewModel.hasNumber, 'One number'),
      (viewModel.hasSpecialCharacter, 'One special character'),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: rules
          .map(
            (rule) => Text(
              '${rule.$1 ? '✓' : '○'} ${rule.$2}',
              style: AppTypography.manropeRegular.copyWith(
                fontSize: 12,
                color: rule.$1
                    ? AppColors.successGreen
                    : AppColors.textSecondary,
              ),
            ),
          )
          .toList(),
    );
  }
}
