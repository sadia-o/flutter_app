import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../app/navigation/route_names.dart';
import '../../../core/widgets/primary_button.dart';
import '../view_models/request_access_view_model.dart';
import '../widgets/request_access_intro_card.dart';

class RequestAccessScreen extends StatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _messageController = TextEditingController();

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _departmentFocus = FocusNode();
  final _messageFocus = FocusNode();

  bool _hasNavigated = false;
  RequestAccessViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel = context.read<RequestAccessViewModel>()
        ..addListener(_onViewModelChange);
    });
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChange);
    _fullNameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _messageController.dispose();

    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _companyFocus.dispose();
    _phoneFocus.dispose();
    _departmentFocus.dispose();
    _messageFocus.dispose();

    // We can't easily remove listener here without storing the viewmodel reference,
    // but the ViewModel is provided above this widget so it will be disposed anyway.
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;
    final viewModel = context.read<RequestAccessViewModel>();

    if (viewModel.isSubmitted) {
      if (!_hasNavigated) {
        _hasNavigated = true;
        // The listener is still active, but _hasNavigated prevents re-triggering.
        Navigator.of(context).pushReplacementNamed(RouteNames.requestSubmitted);
      }
    } else {
      // Reset navigation tracker if the form is edited and isSubmitted becomes false
      _hasNavigated = false;
    }
  }

  void _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<RequestAccessViewModel>();
    await viewModel.submit();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RequestAccessViewModel>();

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
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 4,
                          ), // Visual alignment with button
                          Text(
                            'Request System Access',
                            style: AppTypography.manropeExtraBold.copyWith(
                              fontSize: 20,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your request will be reviewed by an admin',
                            style: AppTypography.manropeRegular.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      const RequestAccessIntroCard(),
                      const SizedBox(height: AppSpacing.xl),

                      // Main Form Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.05,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (viewModel.generalError != null) ...[
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.redTint,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                  border: Border.all(
                                    color: AppColors.criticalRed.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.criticalRed,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        viewModel.generalError!,
                                        style: AppTypography.manropeMedium
                                            .copyWith(
                                              color: AppColors.criticalRed,
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
                              label: 'Full Name',
                              hintText: 'John Smith',
                              controller: _fullNameController,
                              focusNode: _fullNameFocus,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              errorText: viewModel.fullNameError,
                              onChanged: viewModel.setFullName,
                              onFieldSubmitted: (_) =>
                                  _emailFocus.requestFocus(),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            AppTextField(
                              label: 'Company Email',
                              hintText: 'john@company.com',
                              controller: _emailController,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              errorText: viewModel.emailError,
                              onChanged: viewModel.setEmail,
                              onFieldSubmitted: (_) =>
                                  _companyFocus.requestFocus(),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            AppTextField(
                              label: 'Company / Organisation',
                              hintText: 'Acme Corp',
                              controller: _companyController,
                              focusNode: _companyFocus,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.organizationName,
                              ],
                              errorText: viewModel.companyError,
                              onChanged: viewModel.setCompany,
                              onFieldSubmitted: (_) =>
                                  _phoneFocus.requestFocus(),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            AppTextField(
                              label: 'Phone Number',
                              hintText: '+1 555 000 0000',
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              errorText: viewModel.phoneError,
                              onChanged: viewModel.setPhone,
                              onFieldSubmitted: (_) =>
                                  _departmentFocus.requestFocus(),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            AppTextField(
                              label: 'Department',
                              hintText: 'Facilities',
                              isOptional: true,
                              controller: _departmentController,
                              focusNode: _departmentFocus,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              errorText: viewModel.departmentError,
                              onChanged: viewModel.setDepartment,
                              onFieldSubmitted: (_) =>
                                  _messageFocus.requestFocus(),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            AppTextField(
                              label: 'Additional Message',
                              hintText: 'Tell us why you need access...',
                              isOptional: true,
                              controller: _messageController,
                              focusNode: _messageFocus,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.done,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 500,
                              errorText: viewModel.messageError,
                              onChanged: viewModel.setMessage,
                              onFieldSubmitted: (_) => _handleSubmit(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),
                      PrimaryButton(
                        text: 'Send Request',
                        isLoading: viewModel.isLoading,
                        onPressed: viewModel.isSubmitted
                            ? () {}
                            : _handleSubmit,
                      ),
                      const SizedBox(
                        height: AppSpacing.xxl,
                      ), // Bottom safe area padding
                      SafeArea(
                        top: false,
                        child: const SizedBox(height: AppSpacing.lg),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
