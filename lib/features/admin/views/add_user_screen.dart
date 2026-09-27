import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/models/user_role.dart';
import '../view_models/add_user_view_model.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AddUserViewModel>().loadFacilities();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<AddUserViewModel>();
    final success = await viewModel.submit();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else if (viewModel.errorMessage != null) {
      AppTopToast.show(context, viewModel.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddUserViewModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.sm,
                AppSpacing.pageHorizontal,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Semantics(
                    label: 'Back to System Management',
                    button: true,
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: InkWell(
                        key: const Key('add_user_back'),
                        onTap: viewModel.isSubmitting
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: Icon(Icons.arrow_back, size: 22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Add User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.manropeExtraBold.copyWith(
                        fontSize: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.sm,
                  AppSpacing.pageHorizontal,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create an approved invitation',
                            style: AppTypography.manropeBold.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'The invited person will activate their account using the approved email.',
                            style: AppTypography.manropeRegular.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _field(
                            label: 'Full Name',
                            hint: 'Full name',
                            error: viewModel.fullNameError,
                            onChanged: (value) => viewModel.fullName = value,
                          ),
                          _field(
                            label: 'Email Address',
                            hint: 'user@company.com',
                            error: viewModel.emailError,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) => viewModel.email = value,
                          ),
                          _field(
                            label: 'Company',
                            hint: 'Company name',
                            error: viewModel.companyError,
                            onChanged: (value) => viewModel.company = value,
                          ),
                          _field(
                            label: 'Phone Number',
                            hint: '+1 555 000 0000',
                            error: viewModel.phoneError,
                            keyboardType: TextInputType.phone,
                            onChanged: (value) => viewModel.phone = value,
                          ),
                          _field(
                            label: 'Department',
                            hint: 'Optional',
                            error: viewModel.departmentError,
                            onChanged: (value) => viewModel.department = value,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Card(
                      child: RadioGroup<UserRole>(
                        groupValue: viewModel.selectedRole,
                        onChanged: (role) {
                          if (!viewModel.isSubmitting && role != null) {
                            viewModel.selectRole(role);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Role', style: AppTypography.manropeBold),
                            const RadioListTile<UserRole>(
                              title: Text('Technician'),
                              value: UserRole.technician,
                            ),
                            const RadioListTile<UserRole>(
                              title: Text('Viewer'),
                              value: UserRole.viewer,
                            ),
                            if (viewModel.roleError != null)
                              _ErrorText(viewModel.roleError!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Assigned Facilities',
                            style: AppTypography.manropeBold,
                          ),
                          if (viewModel.isLoadingFacilities)
                            const Padding(
                              padding: EdgeInsets.all(AppSpacing.xl),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            for (final facility in viewModel.facilities)
                              Semantics(
                                label:
                                    '${facility.name}, ${viewModel.selectedFacilityIds.contains(facility.id) ? 'selected' : 'not selected'}',
                                child: CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    facility.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${facility.stationCount} stations',
                                  ),
                                  value: viewModel.selectedFacilityIds.contains(
                                    facility.id,
                                  ),
                                  onChanged: viewModel.isSubmitting
                                      ? null
                                      : (_) => viewModel.toggleFacility(
                                          facility.id,
                                        ),
                                  activeColor: AppColors.primaryBlue,
                                ),
                              ),
                          if (viewModel.facilityError != null)
                            _ErrorText(viewModel.facilityError!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                child: Semantics(
                  label: 'Create Invitation',
                  button: true,
                  child: PrimaryButton(
                    text: 'Create Invitation',
                    isLoading: viewModel.isSubmitting,
                    onPressed: _submit,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required String? error,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        label: label,
        textField: true,
        child: AppTextField(
          label: label,
          hintText: hint,
          keyboardType: keyboardType,
          errorText: error,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(color: Colors.transparent, child: child),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTypography.manropeRegular.copyWith(
        color: AppColors.criticalRed,
        fontSize: 12,
      ),
    );
  }
}
