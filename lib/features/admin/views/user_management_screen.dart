import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/user_role.dart';
import '../view_models/user_management_view_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({
    super.key,
    required this.onUserTap,
    this.onAddUser,
  });

  final Future<bool?> Function(String userId) onUserTap;
  final Future<bool?> Function()? onAddUser;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserManagementViewModel? _viewModel;
  int _lastRefreshErrorEventId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<UserManagementViewModel>();
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserManagementViewModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onAddUser: widget.onAddUser == null ? null : _openAddUser),
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
                    _Summary(viewModel: viewModel),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      label: 'Search users by name or email',
                      textField: true,
                      child: AppTextField(
                        label: 'Search',
                        hintText: 'Search by name or email',
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: viewModel.updateQuery,
                        suffixIcon: _searchController.text.isEmpty
                            ? const Icon(Icons.search)
                            : Semantics(
                                label: 'Clear search',
                                button: true,
                                child: IconButton(
                                  key: const Key('clear_user_search'),
                                  onPressed: () {
                                    _searchController.clear();
                                    viewModel.updateQuery('');
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Filters(viewModel: viewModel),
                    const SizedBox(height: AppSpacing.md),
                    _ResultCount(viewModel: viewModel),
                    const SizedBox(height: AppSpacing.sm),
                    _Body(
                      viewModel: viewModel,
                      onUserTap: widget.onUserTap,
                      onReset: () {
                        _searchController.clear();
                        viewModel.resetFilters();
                        setState(() {});
                      },
                    ),
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
  const _Header({this.onAddUser});

  final VoidCallback? onAddUser;

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
          Semantics(label: 'Back', button: true, child: const AppBackButton()),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'User Management',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.manropeExtraBold.copyWith(fontSize: 19),
            ),
          ),
          if (onAddUser != null)
            TextButton.icon(
              key: const Key('user_management_add_user'),
              onPressed: onAddUser,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add User'),
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.viewModel});

  final UserManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.divider),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          _Count(label: 'Total', value: viewModel.totalCount),
          _Count(label: 'Active', value: viewModel.activeCount),
          _Count(label: 'Disabled', value: viewModel.disabledCount),
          _Count(label: 'Admins', value: viewModel.adminCount),
          _Count(label: 'Technicians', value: viewModel.technicianCount),
          _Count(label: 'Viewers', value: viewModel.viewerCount),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: AppTypography.manropeExtraBold.copyWith(
              color: AppColors.primaryBlue,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: AppTypography.manropeMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.viewModel});
  final UserManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Role', style: AppTypography.manropeSemiBold),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final filter in UserRoleFilter.values)
              Semantics(
                label: '${_roleFilterLabel(filter)} role filter',
                selected: viewModel.roleFilter == filter,
                button: true,
                child: FilterChip(
                  label: Text(_roleFilterLabel(filter)),
                  selected: viewModel.roleFilter == filter,
                  onSelected: (_) => viewModel.selectRole(filter),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Status', style: AppTypography.manropeSemiBold),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final filter in UserStatusFilter.values)
              Semantics(
                label: '${_statusFilterLabel(filter)} status filter',
                selected: viewModel.statusFilter == filter,
                button: true,
                child: FilterChip(
                  label: Text(_statusFilterLabel(filter)),
                  selected: viewModel.statusFilter == filter,
                  onSelected: (_) => viewModel.selectStatus(filter),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.viewModel});
  final UserManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final count = viewModel.filteredUsers.length;
    return Text(
      '$count user${count == 1 ? '' : 's'} found',
      style: AppTypography.manropeSemiBold.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.viewModel,
    required this.onUserTap,
    required this.onReset,
  });

  final UserManagementViewModel viewModel;
  final Future<bool?> Function(String userId) onUserTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (viewModel.status == UserManagementStatus.initial ||
        viewModel.status == UserManagementStatus.loading) {
      return const SizedBox(
        height: 260,
        child: AppLoadingState(message: 'Loading users...'),
      );
    }
    if (viewModel.status == UserManagementStatus.failure ||
        viewModel.status == UserManagementStatus.denied) {
      return SizedBox(
        height: 300,
        child: AppErrorState(
          title: viewModel.status == UserManagementStatus.denied
              ? 'Access denied'
              : 'Users unavailable',
          message:
              viewModel.errorMessage ??
              'Users could not be loaded. Check your connection and try again.',
          onRetry: viewModel.load,
        ),
      );
    }
    if (viewModel.users.isEmpty) {
      return const _EmptyMessage(message: 'No users found.');
    }
    final users = viewModel.filteredUsers;
    if (users.isEmpty) {
      return _EmptyMessage(
        message: 'No users match your search or filters.',
        actionLabel: 'Reset search and filters',
        onAction: onReset,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (var index = 0; index < users.length; index++) ...[
            _UserRow(
              user: users[index],
              onTap: () async {
                final changed = await onUserTap(users[index].id);
                if (changed == true) await viewModel.refresh();
              },
            ),
            if (index != users.length - 1)
              const Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onTap});
  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = UserManagementViewModel.displayName(user);
    return Semantics(
      label:
          '$name, ${_roleLabel(user.role)}, '
          '${user.isActive ? 'Active' : 'Disabled'}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.blueLightTint,
                child: Text(
                  UserManagementViewModel.initials(user),
                  style: AppTypography.manropeBold.copyWith(
                    color: AppColors.primaryBlue,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.manropeBold.copyWith(fontSize: 13),
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
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _Badge(
                          label: _roleLabel(user.role),
                          color: _roleColor(user.role),
                        ),
                        _Badge(
                          label: user.isActive ? 'Active' : 'Disabled',
                          color: user.isActive
                              ? AppColors.successGreen
                              : AppColors.criticalRed,
                        ),
                        if (user.siteAccessIds.isNotEmpty)
                          _Badge(
                            label:
                                '${user.siteAccessIds.length} '
                                'facilit${user.siteAccessIds.length == 1 ? 'y' : 'ies'}',
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: AppTypography.manropeSemiBold.copyWith(
            color: color,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message, this.actionLabel, this.onAction});
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(
            Icons.group_off_outlined,
            color: AppColors.textTertiary,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.manropeMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

String _roleFilterLabel(UserRoleFilter filter) => switch (filter) {
  UserRoleFilter.all => 'All',
  UserRoleFilter.admin => 'Admin',
  UserRoleFilter.technician => 'Technician',
  UserRoleFilter.viewer => 'Viewer',
};

String _statusFilterLabel(UserStatusFilter filter) => switch (filter) {
  UserStatusFilter.all => 'All',
  UserStatusFilter.active => 'Active',
  UserStatusFilter.disabled => 'Disabled',
};

String _roleLabel(UserRole role) => switch (role) {
  UserRole.admin => 'Admin',
  UserRole.technician => 'Technician',
  UserRole.viewer => 'Viewer',
};

class UserManagementAccessDeniedScreen extends StatelessWidget {
  const UserManagementAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AppErrorState(
          title: 'Access denied',
          message: 'You do not have permission to manage users.',
          onRetry: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

Color _roleColor(UserRole role) => switch (role) {
  UserRole.admin => AppColors.primaryBlue,
  UserRole.technician => AppColors.successGreen,
  UserRole.viewer => AppColors.textSecondary,
};
