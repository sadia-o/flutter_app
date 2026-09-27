import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/user_role.dart';
import '../view_models/user_details_view_model.dart';
import '../view_models/user_management_view_model.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key, this.onManageUser});

  final Future<bool?> Function(String userId)? onManageUser;

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  bool _changed = false;

  Future<void> _manage(UserDetailsViewModel viewModel) async {
    final target = viewModel.user;
    if (target == null) return;
    final result = await widget.onManageUser?.call(target.id);
    if (!mounted || result != true) return;
    _changed = true;
    await viewModel.load();
  }

  void _back() => Navigator.of(context).pop(_changed);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserDetailsViewModel>();
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
              _Header(onBack: _back),
              Expanded(
                child: _Body(
                  viewModel: viewModel,
                  onManage: viewModel.canManageTarget
                      ? () => _manage(viewModel)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;
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
            label: 'Back',
            button: true,
            child: AppBackButton(onPressed: onBack),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'User Details',
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
  const _Body({required this.viewModel, required this.onManage});
  final UserDetailsViewModel viewModel;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    if (viewModel.status == UserDetailsStatus.initial ||
        viewModel.status == UserDetailsStatus.loading) {
      return const AppLoadingState(message: 'Loading user details...');
    }
    if (viewModel.status == UserDetailsStatus.failure ||
        viewModel.status == UserDetailsStatus.denied ||
        viewModel.status == UserDetailsStatus.missing) {
      return AppErrorState(
        title: viewModel.status == UserDetailsStatus.missing
            ? 'User not found'
            : viewModel.status == UserDetailsStatus.denied
            ? 'Access denied'
            : 'User unavailable',
        message:
            viewModel.errorMessage ??
            'Users could not be loaded. Check your connection and try again.',
        onRetry: viewModel.status == UserDetailsStatus.denied
            ? () => Navigator.of(context).maybePop()
            : viewModel.load,
      );
    }
    final user = viewModel.user!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        AppSpacing.xxl,
      ),
      children: [
        _ProfileCard(user: user),
        if (onManage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: 'Manage User',
            button: true,
            child: ElevatedButton.icon(
              key: const Key('manage_user_action'),
              onPressed: onManage,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Manage User'),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _InformationCard(user: user),
        const SizedBox(height: AppSpacing.md),
        _FacilityCard(viewModel: viewModel),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.blueLightTint,
            child: Text(
              UserManagementViewModel.initials(user),
              style: AppTypography.manropeExtraBold.copyWith(
                color: AppColors.primaryBlue,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            UserManagementViewModel.displayName(user),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.manropeExtraBold.copyWith(fontSize: 18),
          ),
          Text(
            user.email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.manropeRegular.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              _Pill(label: _roleLabel(user.role), color: _roleColor(user.role)),
              _Pill(
                label: user.isActive ? 'Active' : 'Disabled',
                color: user.isActive
                    ? AppColors.successGreen
                    : AppColors.criticalRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String? value})>[
      (label: 'First name', value: user.firstName),
      (label: 'Last name', value: user.lastName),
      (label: 'Company', value: user.company),
      (label: 'Department', value: user.department),
      (label: 'Phone', value: user.phoneNumber),
      (label: 'Job title', value: user.jobTitle),
      (label: 'Short bio', value: user.shortBio),
      (label: 'Created', value: _date(user.createdAt)),
      (label: 'Last updated', value: _date(user.updatedAt)),
    ].where((row) => row.value?.trim().isNotEmpty ?? false).toList();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile information', style: AppTypography.manropeBold),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            Text(
              'No additional profile information.',
              style: AppTypography.manropeRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            for (final row in rows)
              _InfoRow(label: row.label, value: row.value!),
        ],
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.viewModel});
  final UserDetailsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned facilities (${viewModel.facilities.length})',
            style: AppTypography.manropeBold,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (viewModel.facilities.isEmpty)
            Text(
              'No facilities assigned.',
              style: AppTypography.manropeRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            for (final facility in viewModel.facilities)
              Semantics(
                label: 'Assigned facility ${facility.name}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          facility.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
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
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: AppTypography.manropeMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.manropeSemiBold.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: AppTypography.manropeSemiBold.copyWith(
            color: color,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

String _roleLabel(UserRole role) => switch (role) {
  UserRole.admin => 'Admin',
  UserRole.technician => 'Technician',
  UserRole.viewer => 'Viewer',
};

Color _roleColor(UserRole role) => switch (role) {
  UserRole.admin => AppColors.primaryBlue,
  UserRole.technician => AppColors.successGreen,
  UserRole.viewer => AppColors.textSecondary,
};

String? _date(DateTime? value) {
  if (value == null) return null;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
