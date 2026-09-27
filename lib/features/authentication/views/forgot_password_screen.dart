import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../core/widgets/primary_button.dart';
import '../view_models/forgot_password_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit({bool resend = false}) async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<ForgotPasswordViewModel>();
    final succeeded = resend
        ? await viewModel.resend()
        : await viewModel.submit();
    if (!mounted || succeeded || viewModel.errorMessage == null) return;
    AppTopToast.show(context, viewModel.errorMessage!);
  }

  void _backToLogin() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ForgotPasswordViewModel>();

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    AppBackButton(onPressed: _backToLogin),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Password recovery',
                        style: AppTypography.manropeExtraBold.copyWith(
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        AppSpacing.lg,
                        AppSpacing.pageHorizontal,
                        AppSpacing.lg,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - AppSpacing.xxl,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: viewModel.isSuccess
                                  ? _SuccessCard(
                                      key: const ValueKey('success'),
                                      isLoading: viewModel.isLoading,
                                      onResend: () => _submit(resend: true),
                                      onBack: _backToLogin,
                                    )
                                  : _FormCard(
                                      key: const ValueKey('form'),
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      emailError: viewModel.emailError,
                                      isLoading: viewModel.isLoading,
                                      onChanged: viewModel.setEmail,
                                      onSubmit: _submit,
                                      onBack: _backToLogin,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.emailError,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmit,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? emailError;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _RecoveryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RecoveryIcon(icon: Icons.lock_reset_rounded),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Forgot password?',
            textAlign: TextAlign.center,
            style: AppTypography.manropeExtraBold.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter the email address linked to your Bait Guard account. '
            'We’ll send instructions to reset your password.',
            textAlign: TextAlign.center,
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Email Address',
            hintText: 'you@company.com',
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            errorText: emailError,
            onChanged: onChanged,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            text: 'Send Reset Link',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onBack, child: const Text('Back to Login')),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    super.key,
    required this.isLoading,
    required this.onResend,
    required this.onBack,
  });

  final bool isLoading;
  final VoidCallback onResend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _RecoveryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RecoveryIcon(icon: Icons.mark_email_read_outlined),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Check your email',
            textAlign: TextAlign.center,
            style: AppTypography.manropeExtraBold.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'If an account exists for this email, password reset '
            'instructions have been sent.',
            textAlign: TextAlign.center,
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            text: 'Resend Link',
            isLoading: isLoading,
            onPressed: onResend,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onBack, child: const Text('Back to Login')),
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RecoveryIcon extends StatelessWidget {
  const _RecoveryIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.blueLightTint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 30),
      ),
    );
  }
}
