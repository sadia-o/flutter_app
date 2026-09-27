import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../view_models/review_access_request_view_model.dart';

class RejectRequestDialog extends StatelessWidget {
  const RejectRequestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReviewAccessRequestViewModel>();
    final applicant = viewModel.request.request;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      title: const Text('Reject access request?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${applicant.fullName}\n${applicant.email}',
              style: AppTypography.manropeSemiBold,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This request will be marked as rejected. '
              'The applicant will not receive access.',
              style: AppTypography.manropeRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('rejection_reason'),
              enabled: !viewModel.isSubmitting,
              maxLength: 300,
              maxLines: 4,
              onChanged: viewModel.setRejectionReason,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                errorText: viewModel.reasonError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
            ),
            if (viewModel.errorMessage != null)
              Text(
                viewModel.errorMessage!,
                style: AppTypography.manropeRegular.copyWith(
                  color: AppColors.criticalRed,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: viewModel.isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm_reject_request'),
          onPressed: viewModel.isSubmitting
              ? null
              : () async {
                  final rejected = await viewModel.reject();
                  if (!context.mounted || !rejected) return;
                  Navigator.of(context).pop(viewModel.request.id);
                },
          style: FilledButton.styleFrom(backgroundColor: AppColors.criticalRed),
          child: viewModel.isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Reject Request'),
        ),
      ],
    );
  }
}
