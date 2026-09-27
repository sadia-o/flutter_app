import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../domain/models/user_settings.dart';
import '../view_models/settings_preferences_view_model.dart';
import 'widgets/settings_preference_scaffold.dart';

class DefaultAlertFilterScreen extends StatelessWidget {
  const DefaultAlertFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsPreferencesViewModel>(
      builder: (context, viewModel, _) {
        return SettingsPreferenceScaffold(
          title: 'Alert Filters',
          subtitle: 'Configure starting notification filters',
          sectionLabel: 'FILTER MODE PRESET',
          saveLabel: 'Save Filter Preset',
          isSaving: viewModel.isSaving,
          onSave: () => _save(context, viewModel),
          child: SettingsSelectionCard(
            children: [
              _tile(
                viewModel,
                AlertFilterType.all,
                'All Alerts',
                'Display all telemetry exceptions and reports',
                Icons.notifications_none,
                AppColors.primaryBlue,
                AppColors.blueSoftTint,
              ),
              _tile(
                viewModel,
                AlertFilterType.rodent,
                'Rodent Only',
                'Filter specifically for rodent detection alerts',
                Icons.warning_amber_rounded,
                AppColors.criticalRed,
                AppColors.redTint,
              ),
              _tile(
                viewModel,
                AlertFilterType.lowBait,
                'Low Bait Only',
                'Limit alerts to status below 25% levels',
                Icons.warning_amber_rounded,
                AppColors.warningAmber,
                AppColors.amberTint,
              ),
              _tile(
                viewModel,
                AlertFilterType.tamper,
                'Tamper Only',
                'Filter for physically compromised detectors',
                Icons.shield_outlined,
                AppColors.purple,
                AppColors.purpleTint,
              ),
              _tile(
                viewModel,
                AlertFilterType.offline,
                'Offline Only',
                'Track non-responsive network nodes',
                Icons.wifi_off,
                AppColors.textSecondary,
                AppColors.background,
              ),
            ],
          ),
        );
      },
    );
  }

  SettingsSelectionTile _tile(
    SettingsPreferencesViewModel viewModel,
    AlertFilterType value,
    String title,
    String description,
    IconData icon,
    Color iconColor,
    Color background,
  ) {
    return SettingsSelectionTile(
      key: ValueKey('alertFilter_${value.name}'),
      title: title,
      description: description,
      icon: icon,
      iconColor: iconColor,
      iconBackground: background,
      selected: viewModel.selectedAlertFilter == value,
      onTap: () => viewModel.selectAlertFilter(value),
    );
  }

  Future<void> _save(
    BuildContext context,
    SettingsPreferencesViewModel viewModel,
  ) async {
    final settings = await viewModel.saveAlertFilter();
    if (!context.mounted) return;
    if (settings == null) {
      AppTopToast.show(
        context,
        viewModel.errorMessage ?? 'Failed to save preference.',
      );
      return;
    }
    Navigator.of(context).pop(settings);
  }
}
