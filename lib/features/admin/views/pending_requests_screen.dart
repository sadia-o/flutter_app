import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../domain/models/access_request_record.dart';
import '../../../domain/models/user_role.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../domain/repositories/access_request_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../view_models/review_access_request_view_model.dart';
import 'reject_request_dialog.dart';
import '../view_models/pending_requests_view_model.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({
    super.key,
    this.onApproveRequest,
    this.onRequestReviewed,
  });

  final Future<String?> Function(AccessRequestRecord request)? onApproveRequest;
  final Future<void> Function(AccessRequestRecord request)? onRequestReviewed;

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  int _lastRefreshErrorEventId = 0;
  PendingRequestsViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<PendingRequestsViewModel>();
    if (identical(_viewModel, next)) return;
    _viewModel?.removeListener(_onViewModelChanged);
    _viewModel = next..addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (!mounted || _viewModel == null) return;
    if (_viewModel!.refreshErrorEventId > _lastRefreshErrorEventId) {
      _lastRefreshErrorEventId = _viewModel!.refreshErrorEventId;
      final message = _viewModel!.refreshErrorMessage;
      if (message != null) AppTopToast.show(context, message);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PendingRequestsViewModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(count: viewModel.pendingCount),
            Expanded(child: _buildBody(viewModel)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(PendingRequestsViewModel viewModel) {
    if (viewModel.status == PendingRequestsStatus.initial ||
        viewModel.status == PendingRequestsStatus.loading &&
            viewModel.requests.isEmpty) {
      return const AppLoadingState(message: 'Loading pending requests...');
    }
    if (viewModel.status == PendingRequestsStatus.failure &&
        viewModel.requests.isEmpty) {
      return AppErrorState(
        message:
            viewModel.errorMessage ??
            'Unable to load pending requests right now.',
        onRetry: viewModel.load,
      );
    }
    if (viewModel.requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.refresh,
        color: AppColors.primaryBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.xxl,
          ),
          children: [
            const SizedBox(height: 72),
            const Icon(
              Icons.mark_email_read_outlined,
              size: 56,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No pending requests',
              textAlign: TextAlign.center,
              style: AppTypography.manropeBold,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'New access requests will appear here for review.',
              textAlign: TextAlign.center,
              style: AppTypography.manropeRegular,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: AppColors.primaryBlue,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.sm,
          AppSpacing.pageHorizontal,
          AppSpacing.xxl,
        ),
        itemCount: viewModel.requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final request = viewModel.requests[index];
          return _RequestCard(
            request: request,
            onApprove: () => _approve(request),
            onReject: () => _reject(request),
          );
        },
      ),
    );
  }

  Future<void> _approve(AccessRequestRecord request) async {
    final launcher = widget.onApproveRequest;
    if (launcher == null) {
      AppTopToast.show(context, 'Unable to open this request right now.');
      return;
    }
    final reviewedId = await launcher(request);
    if (!mounted || reviewedId == null) return;
    await _completeReview(request, reviewedId, 'Access request approved.');
  }

  Future<void> _reject(AccessRequestRecord request) async {
    final reviewer = context.read<AppSessionController>().currentUser;
    if (reviewer == null ||
        reviewer.role != UserRole.admin ||
        !reviewer.isActive) {
      return;
    }
    final reviewedId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider(
        create: (_) => ReviewAccessRequestViewModel(
          request: request,
          reviewer: reviewer,
          accessRequestRepository: context.read<AccessRequestRepository>(),
          settingsRepository: context.read<SettingsRepository>(),
        ),
        child: const RejectRequestDialog(),
      ),
    );
    if (!mounted || reviewedId == null) return;
    await _completeReview(request, reviewedId, 'Access request rejected.');
  }

  Future<void> _completeReview(
    AccessRequestRecord request,
    String requestId,
    String message,
  ) async {
    context.read<PendingRequestsViewModel>().removeReviewedRequest(requestId);
    await widget.onRequestReviewed?.call(request);
    if (!mounted) return;
    AppTopToast.show(context, message);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

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
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              key: const Key('pending_requests_back'),
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Icon(Icons.arrow_back, size: 22),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Pending Requests',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.manropeExtraBold.copyWith(fontSize: 19),
            ),
          ),
          Container(
            key: const Key('pending_requests_count_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.criticalRed,
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Text(
              '$count',
              style: AppTypography.manropeBold.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final AccessRequestRecord request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final data = request.request;
    final organization = [
      data.company,
      data.department,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    final message = data.message.trim().isEmpty
        ? 'No additional message provided.'
        : data.message.trim();

    return Container(
      key: Key('pending_request_${request.id}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  _initials(data.fullName),
                  style: AppTypography.manropeBold.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.manropeBold.copyWith(fontSize: 14),
                    ),
                    if (organization.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        organization,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.manropeRegular.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatDate(data.submittedAt),
                style: AppTypography.manropeRegular.copyWith(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.email,
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: Key('approve_${request.id}'),
                  onPressed: onApprove,
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  key: Key('reject_${request.id}'),
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.criticalRed,
                    side: const BorderSide(color: AppColors.criticalRed),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
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

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Pending';
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);
    final time = DateFormat('h:mm a').format(local);
    if (date == today) return 'Today, $time';
    if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    }
    return DateFormat('MMM d, y').format(local);
  }
}

class PendingRequestsAccessDeniedScreen extends StatelessWidget {
  const PendingRequestsAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AppErrorState(
          message: 'You do not have permission to review access requests.',
          onRetry: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
