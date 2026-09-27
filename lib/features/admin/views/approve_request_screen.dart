import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/models/user_role.dart';
import '../view_models/review_access_request_view_model.dart';

class ApproveRequestScreen extends StatefulWidget {
  const ApproveRequestScreen({super.key});

  @override
  State<ApproveRequestScreen> createState() => _ApproveRequestScreenState();
}

class _ApproveRequestScreenState extends State<ApproveRequestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReviewAccessRequestViewModel>().loadFacilities();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReviewAccessRequestViewModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
              child: Row(
                children: [
                  IconButton(
                    onPressed: viewModel.isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Approve Request',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ApplicantSummary(viewModel: viewModel),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      title: 'Assign role',
                      child: RadioGroup<UserRole>(
                        groupValue: viewModel.selectedRole,
                        onChanged: (role) {
                          if (!viewModel.isSubmitting && role != null) {
                            viewModel.selectRole(role);
                          }
                        },
                        child: Column(
                          children: [
                            const _RoleTile(
                              label: 'Technician',
                              role: UserRole.technician,
                            ),
                            const _RoleTile(
                              label: 'Viewer',
                              role: UserRole.viewer,
                            ),
                            if (viewModel.roleError != null)
                              _ErrorText(viewModel.roleError!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      title: 'Assign facilities',
                      child: viewModel.isLoadingFacilities
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                for (final facility in viewModel.facilities)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(facility.name),
                                    subtitle: Text(
                                      '${facility.stationCount} stations',
                                    ),
                                    value: viewModel.selectedFacilityIds
                                        .contains(facility.id),
                                    onChanged: viewModel.isSubmitting
                                        ? null
                                        : (_) => viewModel.toggleFacility(
                                            facility.id,
                                          ),
                                    activeColor: AppColors.primaryBlue,
                                  ),
                                if (viewModel.facilityError != null)
                                  _ErrorText(viewModel.facilityError!),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(
                      title: 'Confirmation',
                      child: Text(
                        viewModel.selectedRole == null
                            ? 'Select a role and at least one facility.'
                            : '${_roleLabel(viewModel.selectedRole!)} · '
                                  '${viewModel.selectedFacilityIds.length} '
                                  '${viewModel.selectedFacilityIds.length == 1 ? 'facility' : 'facilities'}',
                        style: AppTypography.manropeRegular.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (viewModel.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ErrorText(viewModel.errorMessage!),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                child: PrimaryButton(
                  text: 'Approve Access',
                  isLoading: viewModel.isSubmitting,
                  onPressed: () async {
                    final approved = await viewModel.approve();
                    if (!context.mounted || !approved) return;
                    Navigator.of(context).pop(viewModel.request.id);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _roleLabel(UserRole role) =>
      role == UserRole.technician ? 'Technician' : 'Viewer';
}

class _ApplicantSummary extends StatelessWidget {
  const _ApplicantSummary({required this.viewModel});

  final ReviewAccessRequestViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final applicant = viewModel.request.request;
    final lines = [
      applicant.email,
      applicant.company,
      applicant.department,
      applicant.phone,
      applicant.message,
    ].where((value) => value.trim().isNotEmpty);
    return _SectionCard(
      title: applicant.fullName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              _initials(applicant.fullName),
              style: AppTypography.manropeBold.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                line,
                style: AppTypography.manropeRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTypography.manropeBold),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.label, required this.role});

  final String label;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<UserRole>(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: role,
      activeColor: AppColors.primaryBlue,
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
