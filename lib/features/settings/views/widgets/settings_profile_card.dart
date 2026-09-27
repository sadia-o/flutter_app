import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../domain/models/app_user.dart';

class SettingsProfileCard extends StatelessWidget {
  final AppUser user;
  final String? activeFacilityName;
  final VoidCallback onEditTap;

  const SettingsProfileCard({
    super.key,
    required this.user,
    required this.activeFacilityName,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Dark blue top banner
          Container(height: 60, color: AppColors.splashBackground),
          // Content overlapping banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar row
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                _initials(user.name),
                                style: AppTypography.manropeBold.copyWith(
                                  fontSize: 24,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.borderSecondary,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: onEditTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                            side: const BorderSide(
                              color: AppColors.borderSecondary,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 0,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        child: Text(
                          'Edit Profile',
                          style: AppTypography.manropeBold.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Name and email
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppTypography.manropeExtraBold.copyWith(
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: AppTypography.manropeRegular.copyWith(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purpleTint,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                            child: Text(
                              user.role.name.toUpperCase(),
                              style: AppTypography.manropeBold.copyWith(
                                fontSize: 12,
                                color: AppColors.purple,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (activeFacilityName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blueTint,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                              ),
                              child: Text(
                                activeFacilityName!,
                                style: AppTypography.manropeBold.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Verified strip
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: AppSpacing.md,
            ),
            color: AppColors.greenTint,
            child: Row(
              children: [
                const Icon(
                  Icons.verified,
                  size: 16,
                  color: AppColors.successGreen,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Verified Enterprise Account',
                  style: AppTypography.manropeMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.alternateSuccess,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}
