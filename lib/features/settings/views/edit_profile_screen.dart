import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/app_top_toast.dart';
import '../view_models/edit_profile_view_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _departmentCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    final vm = context.read<EditProfileViewModel>();
    _firstNameCtrl = TextEditingController(text: vm.firstName);
    _lastNameCtrl = TextEditingController(text: vm.lastName);
    _jobTitleCtrl = TextEditingController(text: vm.jobTitle);
    _departmentCtrl = TextEditingController(text: vm.department);
    _phoneCtrl = TextEditingController(text: vm.phoneNumber);
    _bioCtrl = TextEditingController(text: vm.shortBio);

    // Keep vm state in sync as the user types
    _firstNameCtrl.addListener(() => vm.firstName = _firstNameCtrl.text);
    _lastNameCtrl.addListener(() => vm.lastName = _lastNameCtrl.text);
    _jobTitleCtrl.addListener(() => vm.jobTitle = _jobTitleCtrl.text);
    _departmentCtrl.addListener(() => vm.department = _departmentCtrl.text);
    _phoneCtrl.addListener(() => vm.phoneNumber = _phoneCtrl.text);
    _bioCtrl.addListener(() {
      vm.shortBio = _bioCtrl.text;
      setState(() {}); // re-render char counter
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _jobTitleCtrl.dispose();
    _departmentCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!mounted) return;
    final vm = context.read<EditProfileViewModel>();
    final validationError = vm.validate();
    if (validationError != null) {
      AppTopToast.show(context, validationError);
      return;
    }
    final ok = await vm.save();
    if (!mounted) return;
    if (ok) {
      AppTopToast.show(context, 'Profile updated successfully.');
      Navigator.of(context).pop();
    } else {
      AppTopToast.show(context, vm.errorMessage ?? 'Failed to save profile.');
    }
  }

  String _getFacilityLabel() {
    return context.read<EditProfileViewModel>().assignedFacilityName;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Consumer<EditProfileViewModel>(
        builder: (context, vm, _) {
          final user = vm.currentUser;
          if (user == null) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final initials = _initials(user.name);

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  // ── Fixed header ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              border: Border.all(
                                color: AppColors.borderSecondary,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profile',
                              style: AppTypography.manropeBold.copyWith(
                                fontSize: 22,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Update your personal information',
                              style: AppTypography.manropeRegular.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // ── Scrollable form body ──────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpacing.xl),

                            // Avatar
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: AppColors.primaryBlue,
                              child: Text(
                                initials,
                                style: AppTypography.manropeBold.copyWith(
                                  fontSize: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Profile initials are generated from your name.',
                              textAlign: TextAlign.center,
                              style: AppTypography.manropeRegular.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Role + facility chips
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _chip(
                                  user.role.name[0].toUpperCase() +
                                      user.role.name.substring(1),
                                  AppColors.purpleTint,
                                  AppColors.purple,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _chip(
                                  _getFacilityLabel(),
                                  AppColors.blueTint,
                                  AppColors.primaryBlue,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // ── PERSONAL INFORMATION ───────────────────
                            _sectionLabel('PERSONAL INFORMATION'),
                            _card([
                              // First / Last name row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _labeledField(
                                      label: 'First Name',
                                      controller: _firstNameCtrl,
                                      hint: 'First name',
                                      enabled: !vm.isSaving,
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: _labeledField(
                                      label: 'Last Name',
                                      controller: _lastNameCtrl,
                                      hint: 'Last name',
                                      enabled: !vm.isSaving,
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _labeledField(
                                label: 'Job Title',
                                controller: _jobTitleCtrl,
                                hint: 'e.g. Field Operator',
                                enabled: !vm.isSaving,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _labeledField(
                                label: 'Department',
                                controller: _departmentCtrl,
                                hint: 'e.g. Facilities Management',
                                enabled: !vm.isSaving,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              // Read-only: Assigned Location
                              _readOnlyField(
                                label: 'Assigned Location',
                                value: _getFacilityLabel(),
                                note:
                                    'Set by your administrator — contact them to change.',
                              ),
                            ]),
                            const SizedBox(height: AppSpacing.xl),

                            // ── CONTACT INFORMATION ────────────────────
                            _sectionLabel('CONTACT INFORMATION'),
                            _card([
                              // Read-only: Company Email
                              _readOnlyField(
                                label: 'Company Email',
                                value: user.email,
                                badge: 'Managed by admin',
                                note:
                                    'Email address is managed by your system administrator.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _labeledField(
                                label: 'Phone Number',
                                controller: _phoneCtrl,
                                hint: '+1 555 012 3456',
                                enabled: !vm.isSaving,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                              ),
                            ]),
                            const SizedBox(height: AppSpacing.xl),

                            // ── ABOUT ──────────────────────────────────
                            _sectionLabel('ABOUT'),
                            _card([
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Short Bio',
                                    style: AppTypography.manropeBold.copyWith(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${vm.bioCharCount} / ${EditProfileViewModel.maxBioLength}',
                                    style: AppTypography.manropeRegular
                                        .copyWith(
                                          fontSize: 12,
                                          color:
                                              vm.bioCharCount >
                                                  EditProfileViewModel
                                                      .maxBioLength
                                              ? AppColors.criticalRed
                                              : AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _bioCtrl,
                                enabled: !vm.isSaving,
                                maxLines: 4,
                                maxLength: EditProfileViewModel.maxBioLength,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                decoration: _inputDecoration(
                                  'Tell your team a little about yourself...',
                                ),
                                style: AppTypography.manropeRegular.copyWith(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                buildCounter:
                                    (
                                      context, {
                                      required currentLength,
                                      required isFocused,
                                      maxLength,
                                    }) => const SizedBox.shrink(),
                              ),
                            ]),
                            // Bottom padding so content clears the fixed action bar
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Fixed bottom action bar ──────────────────────────────
            bottomNavigationBar: SafeArea(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: vm.isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(
                            color: AppColors.borderSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTypography.manropeBold.copyWith(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: vm.isSaving ? null : _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primaryBlue
                              .withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: vm.isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: AppTypography.manropeBold.copyWith(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty
        ? name.substring(0, name.length.clamp(1, 2)).toUpperCase()
        : '?';
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        label,
        style: AppTypography.manropeBold.copyWith(fontSize: 12, color: fg),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: AppSpacing.xs,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: AppTypography.interBold.copyWith(
            fontSize: 12,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.done,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.manropeBold.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: _inputDecoration(hint),
          style: AppTypography.manropeRegular.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    String? badge,
    String? note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.manropeBold.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.borderSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  badge,
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          initialValue: value,
          readOnly: true,
          enabled: false,
          decoration: _inputDecoration(value),
          style: AppTypography.manropeRegular.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(
            note,
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.manropeRegular.copyWith(
        fontSize: 14,
        color: AppColors.textTertiary,
      ),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: BorderSide.none,
      ),
    );
  }
}
