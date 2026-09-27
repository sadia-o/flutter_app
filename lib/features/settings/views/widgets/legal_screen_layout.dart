import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import 'legal_section.dart';

class LegalSectionData {
  final String title;
  final String body;

  const LegalSectionData({required this.title, required this.body});
}

class LegalScreenLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<LegalSectionData> sections;

  const LegalScreenLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.md,
                AppSpacing.pageHorizontal,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  InkWell(
                    key: const Key('legalScreenBack'),
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.manropeBold.copyWith(
                            fontSize: 22,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.manropeRegular.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('legalScreenScroll'),
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(sections.length * 2 - 1, (index) {
                      if (index.isOdd) {
                        return const Divider(
                          height: 1,
                          color: AppColors.divider,
                        );
                      }
                      final section = sections[index ~/ 2];
                      return LegalSection(
                        title: section.title,
                        body: section.body,
                      );
                    }),
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
