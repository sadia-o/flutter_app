import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../app/navigation/authenticated_destination_resolver.dart';
import '../view_models/login_view_model.dart';
import '../widgets/login_header.dart';
import '../widgets/remember_me_row.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<LoginViewModel>();
      await viewModel.initializeRememberedEmail();
      if (!mounted) return;
      _emailController.text = viewModel.email;
    });
  }

  void _handleLogin() async {
    final viewModel = context.read<LoginViewModel>();

    // Unfocus to dismiss keyboard before attempting login
    FocusScope.of(context).unfocus();

    final success = await viewModel.login();
    if (success && mounted) {
      final sessionController = context.read<AppSessionController>();
      final currentUser = sessionController.currentUser;

      if (currentUser != null) {
        final destination = AuthenticatedDestinationResolver.resolve(
          currentUser.role,
        );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(destination, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const LoginHeader(),

                        // Lower form panel
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(AppRadii.xl * 2),
                                topRight: Radius.circular(AppRadii.xl * 2),
                              ),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.pageHorizontal,
                                  vertical: AppSpacing.xl,
                                ),
                                child: AutofillGroup(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (viewModel.generalError != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.md,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.redTint,
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.md,
                                            ),
                                            border: Border.all(
                                              color: AppColors.criticalRed
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                color: AppColors.criticalRed,
                                                size: 20,
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  viewModel.generalError!,
                                                  style: AppTypography
                                                      .manropeMedium
                                                      .copyWith(
                                                        color: AppColors
                                                            .criticalRed,
                                                        fontSize: 13,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                      ],

                                      AppTextField(
                                        label: 'Email Address',
                                        hintText: 'you@company.com',
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.username,
                                          AutofillHints.email,
                                        ],
                                        errorText: viewModel.emailError,
                                        onChanged: viewModel.setEmail,
                                        onFieldSubmitted: (_) =>
                                            _passwordFocusNode.requestFocus(),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      AppTextField(
                                        label: 'Password',
                                        hintText: '••••••••',
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        obscureText:
                                            !viewModel.isPasswordVisible,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        errorText: viewModel.passwordError,
                                        onChanged: viewModel.setPassword,
                                        onFieldSubmitted: (_) => _handleLogin(),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            viewModel.isPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: AppColors.textTertiary,
                                          ),
                                          onPressed: viewModel
                                              .togglePasswordVisibility,
                                          splashRadius: 20,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      RememberMeRow(
                                        value: viewModel.rememberMe,
                                        onChanged: viewModel.toggleRememberMe,
                                        onForgotPasswordPressed: () {
                                          Navigator.of(context).pushNamed(
                                            RouteNames.forgotPassword,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.xxl),

                                      PrimaryButton(
                                        text: 'Log In',
                                        isLoading: viewModel.isLoading,
                                        onPressed: _handleLogin,
                                      ),
                                      const SizedBox(height: AppSpacing.xxl),

                                      const Divider(
                                        color: AppColors.divider,
                                        height: 1,
                                        thickness: 1,
                                      ),
                                      const SizedBox(height: AppSpacing.xl),

                                      // Contact Administrator Row
                                      Center(
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              'Need access to the system? ',
                                              style: AppTypography
                                                  .manropeRegular
                                                  .copyWith(
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).pushNamed(
                                                  RouteNames.requestAccess,
                                                );
                                              },
                                              child: Text(
                                                'Contact Administrator',
                                                style: AppTypography
                                                    .manropeSemiBold
                                                    .copyWith(
                                                      fontSize: 13,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: AppSpacing.md),
                                      Center(
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          children: [
                                            Text(
                                              'Already approved? ',
                                              style: AppTypography
                                                  .manropeRegular
                                                  .copyWith(
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.of(context)
                                                  .pushNamed(
                                                    RouteNames.activateAccount,
                                                  ),
                                              child: Text(
                                                'Activate your account',
                                                style: AppTypography
                                                    .manropeSemiBold
                                                    .copyWith(
                                                      fontSize: 13,
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: AppSpacing.xl),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
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
