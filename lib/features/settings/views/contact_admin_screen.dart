import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../view_models/contact_admin_view_model.dart';
import 'widgets/settings_preference_scaffold.dart';

class ContactAdminScreen extends StatefulWidget {
  const ContactAdminScreen({super.key});

  @override
  State<ContactAdminScreen> createState() => _ContactAdminScreenState();
}

class _ContactAdminScreenState extends State<ContactAdminScreen> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<ContactAdminViewModel>();
    _messageController = TextEditingController()
      ..addListener(() => viewModel.updateMessage(_messageController.text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      viewModel.load();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactAdminViewModel>(
      builder: (context, viewModel, _) {
        return SettingsPreferenceScaffold(
          title: 'Contact Admin',
          subtitle: 'Get in touch with enterprise support',
          sectionLabel: 'ADMINISTRATOR SUPPORT',
          saveLabel: 'Send Message',
          isSaving: viewModel.isSending,
          onSave: viewModel.isLoading ? null : () => _send(context, viewModel),
          child: viewModel.isLoading
              ? const AppLoadingState(message: 'Loading administrator...')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (viewModel.administrator != null)
                      _administratorCard(viewModel),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Send a Message',
                      style: AppTypography.manropeSemiBold.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      key: const Key('administratorMessageField'),
                      controller: _messageController,
                      enabled: !viewModel.isSending,
                      minLines: 6,
                      maxLines: 8,
                      maxLength: ContactAdminViewModel.maxMessageLength,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      decoration: InputDecoration(
                        hintText:
                            'Write your message or report system issues to the system administrator here...',
                        filled: true,
                        fillColor: AppColors.surface,
                        counterText:
                            '${viewModel.characterCount} / ${ContactAdminViewModel.maxMessageLength}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          borderSide: const BorderSide(
                            color: AppColors.divider,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          borderSide: const BorderSide(
                            color: AppColors.divider,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          borderSide: const BorderSide(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _administratorCard(ContactAdminViewModel viewModel) {
    final administrator = viewModel.administrator!;
    final parts = administrator.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = parts.length > 1
        ? '${parts.first[0]}${parts[1][0]}'.toUpperCase()
        : parts.first.substring(0, 1).toUpperCase();
    final contactLine = [
      administrator.email,
      if (administrator.phoneNumber?.isNotEmpty == true)
        administrator.phoneNumber!,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.blueSoftTint,
            child: Text(
              initials,
              style: AppTypography.manropeBold.copyWith(
                fontSize: 18,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  administrator.name,
                  style: AppTypography.manropeBold.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  administrator.roleLabel,
                  style: AppTypography.manropeBold.copyWith(
                    fontSize: 11,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contactLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(
    BuildContext context,
    ContactAdminViewModel viewModel,
  ) async {
    final success = await viewModel.send();
    if (!context.mounted) return;
    if (!success) {
      AppTopToast.show(
        context,
        viewModel.errorMessage ?? 'Unable to send message.',
      );
      return;
    }
    _messageController.clear();
    Navigator.of(context).pop('Message sent to administrator');
  }
}
