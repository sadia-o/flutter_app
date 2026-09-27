import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/user_role.dart';
import '../view_models/manage_user_view_model.dart';
import '../view_models/user_management_view_model.dart';

class ManageUserScreen extends StatelessWidget {
  const ManageUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageUserViewModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(child: _Body(viewModel: viewModel)),
            if (viewModel.status == ManageUserStatus.ready)
              _BottomAction(viewModel: viewModel),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Back to User Details',
            button: true,
            child: const AppBackButton(),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Manage User',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.manropeExtraBold.copyWith(fontSize: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.viewModel});
  final ManageUserViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.status == ManageUserStatus.initial ||
        viewModel.status == ManageUserStatus.loading) {
      return const AppLoadingState(message: 'Loading user access...');
    }
    if (viewModel.status != ManageUserStatus.ready) {
      return AppErrorState(
        title: viewModel.status == ManageUserStatus.missing
            ? 'User not found'
            : viewModel.status == ManageUserStatus.denied
            ? 'Access denied'
            : 'User unavailable',
        message:
            viewModel.errorMessage ??
            'User details could not be loaded. Check your connection and try again.',
        onRetry:
            viewModel.status == ManageUserStatus.denied ||
                viewModel.status == ManageUserStatus.missing
            ? () => Navigator.of(context).maybePop()
            : viewModel.load,
      );
    }
    final target = viewModel.target!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        AppSpacing.xxl,
      ),
      children: [
        _IdentityCard(user: target),
        const SizedBox(height: AppSpacing.md),
        _RoleCard(viewModel: viewModel),
        const SizedBox(height: AppSpacing.md),
        _FacilitiesCard(viewModel: viewModel),
        const SizedBox(height: AppSpacing.md),
        _StatusCard(viewModel: viewModel),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.blueLightTint,
            child: Text(
              UserManagementViewModel.initials(user),
              style: AppTypography.manropeExtraBold.copyWith(
                color: AppColors.primaryBlue,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UserManagementViewModel.displayName(user),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.manropeBold,
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.manropeRegular.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_roleLabel(user.role)} · '
                  '${user.isActive ? 'Active' : 'Disabled'}',
                  style: AppTypography.manropeSemiBold.copyWith(
                    color: AppColors.primaryBlue,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.viewModel});
  final ManageUserViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Role', style: AppTypography.manropeBold),
          const SizedBox(height: AppSpacing.xs),
          RadioGroup<UserRole>(
            groupValue: viewModel.selectedRole,
            onChanged: (role) {
              if (!viewModel.isSubmitting && role != null) {
                viewModel.selectRole(role);
              }
            },
            child: Column(
              children: [
                for (final role in [UserRole.technician, UserRole.viewer])
                  Semantics(
                    label: '${_roleLabel(role)} role',
                    selected: viewModel.selectedRole == role,
                    child: RadioListTile<UserRole>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_roleLabel(role)),
                      value: role,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilitiesCard extends StatelessWidget {
  const _FacilitiesCard({required this.viewModel});
  final ManageUserViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assigned Facilities', style: AppTypography.manropeBold),
          const SizedBox(height: AppSpacing.xs),
          for (final facility in viewModel.facilities)
            Semantics(
              label:
                  '${facility.name}, '
                  '${viewModel.selectedFacilityIds.contains(facility.id) ? 'selected' : 'not selected'}',
              selected: viewModel.selectedFacilityIds.contains(facility.id),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  facility.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                value: viewModel.selectedFacilityIds.contains(facility.id),
                onChanged: viewModel.isSubmitting
                    ? null
                    : (_) => viewModel.toggleFacility(facility.id),
              ),
            ),
          if (viewModel.facilityError case final error?)
            Text(
              error,
              style: AppTypography.manropeMedium.copyWith(
                color: AppColors.criticalRed,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.viewModel});
  final ManageUserViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Application Status', style: AppTypography.manropeBold),
          RadioGroup<bool>(
            groupValue: viewModel.selectedActive,
            onChanged: (active) {
              if (!viewModel.isSubmitting && active != null) {
                viewModel.selectStatus(active);
              }
            },
            child: Column(
              children: [
                for (final active in [true, false])
                  Semantics(
                    label: active ? 'Active status' : 'Disabled status',
                    selected: viewModel.selectedActive == active,
                    child: RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(active ? 'Active' : 'Disabled'),
                      subtitle: Text(
                        active
                            ? 'The user can sign in and access assigned Bait Guard features.'
                            : 'The user will be denied application access after their profile is checked.',
                      ),
                      value: active,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'This changes Bait Guard application access only. It does not disable the Firebase Authentication account.',
            style: AppTypography.manropeRegular.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.viewModel});
  final ManageUserViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (viewModel.errorMessage case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: AppTypography.manropeMedium.copyWith(
                    color: AppColors.criticalRed,
                    fontSize: 12,
                  ),
                ),
              ),
            Semantics(
              label: 'Save Changes',
              button: true,
              enabled: viewModel.canSubmit,
              child: Opacity(
                opacity: viewModel.canSubmit || viewModel.isSubmitting
                    ? 1
                    : 0.5,
                child: AbsorbPointer(
                  absorbing: !viewModel.canSubmit,
                  child: PrimaryButton(
                    text: 'Save Changes',
                    isLoading: viewModel.isSubmitting,
                    onPressed: () => _save(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (viewModel.willDisable) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Disable user access?'),
          content: const Text(
            'This user will no longer be allowed to enter Bait Guard after '
            'their profile is checked. Their Firebase Authentication account '
            'will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('confirm_disable_user'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.criticalRed,
              ),
              child: const Text('Disable User'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    final success = await viewModel.submit();
    if (!context.mounted) return;
    if (success) {
      AppTopToast.show(context, 'User access updated successfully.');
      Navigator.of(context).pop(true);
    } else if (viewModel.errorMessage != null) {
      AppTopToast.show(context, viewModel.errorMessage!);
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
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
      ),
      child: Material(color: Colors.transparent, child: child),
    );
  }
}

String _roleLabel(UserRole role) => switch (role) {
  UserRole.admin => 'Admin',
  UserRole.technician => 'Technician',
  UserRole.viewer => 'Viewer',
};
