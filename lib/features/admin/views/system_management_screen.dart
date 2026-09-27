import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/settings_facility_option.dart';
import '../../../domain/models/user_role.dart';
import '../view_models/system_management_view_model.dart';

class SystemManagementScreen extends StatefulWidget {
  const SystemManagementScreen({super.key, this.onAddUser, this.onOpenUsers});

  final Future<bool?> Function()? onAddUser;
  final VoidCallback? onOpenUsers;

  @override
  State<SystemManagementScreen> createState() => _SystemManagementScreenState();
}

class _SystemManagementScreenState extends State<SystemManagementScreen> {
  SystemManagementViewModel? _viewModel;
  int _lastRefreshErrorEventId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<SystemManagementViewModel>();
    if (identical(next, _viewModel)) return;
    _viewModel?.removeListener(_onViewModelChanged);
    _viewModel = next..addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    final viewModel = _viewModel;
    if (!mounted ||
        viewModel == null ||
        viewModel.refreshErrorEventId <= _lastRefreshErrorEventId) {
      return;
    }
    _lastRefreshErrorEventId = viewModel.refreshErrorEventId;
    final message = viewModel.refreshErrorMessage;
    if (message != null) AppTopToast.show(context, message);
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SystemManagementViewModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: viewModel.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.sm,
                    AppSpacing.pageHorizontal,
                    AppSpacing.xxl,
                  ),
                  children: [
                    _UserManagementCard(
                      viewModel: viewModel,
                      onAddUser: _openAddUser,
                      onOpenUsers: widget.onOpenUsers,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SiteManagementCard(sites: viewModel.sites),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddUser() async {
    final result = await widget.onAddUser?.call();
    if (!mounted || result != true) return;
    AppTopToast.show(context, 'Invitation created successfully.');
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
            label: 'Back to Admin Dashboard',
            button: true,
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: InkWell(
                key: const Key('system_management_back'),
                onTap: () => Navigator.of(context).maybePop(),
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
              'System Management',
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

class _UserManagementCard extends StatelessWidget {
  const _UserManagementCard({
    required this.viewModel,
    required this.onAddUser,
    required this.onOpenUsers,
  });

  final SystemManagementViewModel viewModel;
  final VoidCallback onAddUser;
  final VoidCallback? onOpenUsers;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'User Management',
      container: true,
      child: _ManagementCard(
        icon: Icons.group_outlined,
        title: 'User Management',
        subtitle: viewModel.status == SystemManagementStatus.success
            ? viewModel.userSummary
            : 'Application users',
        actionLabel: '+ Add User',
        actionKey: const Key('add_user_action'),
        onAction: onAddUser,
        secondaryActionLabel: 'View all users',
        secondaryActionKey: const Key('view_all_users_action'),
        onSecondaryAction: onOpenUsers,
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (viewModel.status == SystemManagementStatus.initial ||
        viewModel.status == SystemManagementStatus.loading) {
      return const SizedBox(
        height: 132,
        child: AppLoadingState(message: 'Loading users...'),
      );
    }
    if (viewModel.status == SystemManagementStatus.failure ||
        viewModel.status == SystemManagementStatus.denied) {
      return SizedBox(
        height: 190,
        child: AppErrorState(
          title: 'Users unavailable',
          message:
              viewModel.errorMessage ??
              'Users could not be loaded. Pull to refresh or try again.',
          onRetry: viewModel.load,
        ),
      );
    }
    if (viewModel.users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Text(
          'No users found.',
          textAlign: TextAlign.center,
          style: AppTypography.manropeMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    final visibleUsers = viewModel.users.take(3).toList(growable: false);
    return Column(
      children: [
        for (var index = 0; index < visibleUsers.length; index++) ...[
          _UserRow(user: visibleUsers[index]),
          if (index != visibleUsers.length - 1)
            const Divider(height: 1, color: AppColors.divider),
        ],
        if (viewModel.users.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '${viewModel.users.length - 3} more users',
              style: AppTypography.manropeMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (user.role) {
      UserRole.admin => 'Admin',
      UserRole.technician => 'Technician',
      UserRole.viewer => 'Viewer',
    };
    final badgeColor = switch (user.role) {
      UserRole.admin => AppColors.primaryBlue,
      UserRole.technician => AppColors.successGreen,
      UserRole.viewer => AppColors.textSecondary,
    };
    return Semantics(
      label:
          '${SystemManagementViewModel.displayName(user)}, $roleLabel, '
          '${user.isActive ? 'active' : 'disabled'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.blueLightTint,
              child: Text(
                SystemManagementViewModel.initials(user),
                style: AppTypography.manropeBold.copyWith(
                  color: AppColors.primaryBlue,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                SystemManagementViewModel.displayName(user),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.manropeBold.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              label: '$roleLabel role',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                child: Text(
                  roleLabel,
                  style: AppTypography.manropeSemiBold.copyWith(
                    color: badgeColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SiteManagementCard extends StatelessWidget {
  const _SiteManagementCard({required this.sites});

  final List<SettingsFacilityOption> sites;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Site Management',
      container: true,
      child: _ManagementCard(
        icon: Icons.business_outlined,
        title: 'Site Management',
        subtitle: '${sites.length} active site${sites.length == 1 ? '' : 's'}',
        actionLabel: '+ Add Site',
        actionKey: const Key('add_site_action'),
        onAction: () => AppTopToast.show(
          context,
          'Add Site will be available after the site backend is confirmed.',
        ),
        child: sites.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'No sites available.',
                  textAlign: TextAlign.center,
                  style: AppTypography.manropeMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : Column(
                children: [
                  for (var index = 0; index < sites.length; index++) ...[
                    _SiteRow(site: sites[index]),
                    if (index != sites.length - 1)
                      const Divider(height: 1, color: AppColors.divider),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SiteRow extends StatelessWidget {
  const _SiteRow({required this.site});

  final SettingsFacilityOption site;

  @override
  Widget build(BuildContext context) {
    final status = site.isHealthy
        ? 'Healthy'
        : '${site.offlineStationCount} offline';
    final color = site.isHealthy
        ? AppColors.successGreen
        : AppColors.warningAmber;
    return Semantics(
      label: '${site.name}, ${site.stationCount} stations, $status',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.manropeBold.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${site.stationCount} stations · $status',
                    style: AppTypography.manropeRegular.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  status,
                  style: AppTypography.manropeMedium.copyWith(
                    color: color,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.actionLabel,
    required this.actionKey,
    required this.onAction,
    this.secondaryActionLabel,
    this.secondaryActionKey,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final String actionLabel;
  final Key actionKey;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final Key? secondaryActionKey;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.manropeBold.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.manropeRegular.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
          if (onSecondaryAction != null && secondaryActionLabel != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: secondaryActionKey,
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ),
          const Divider(height: AppSpacing.xl, color: AppColors.divider),
          Semantics(
            label: actionLabel.replaceFirst('+ ', 'Add '),
            button: true,
            child: TextButton(
              key: actionKey,
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class SystemManagementAccessDeniedScreen extends StatelessWidget {
  const SystemManagementAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AppErrorState(
          title: 'Access denied',
          message: 'You do not have permission to access System Management.',
          onRetry: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
