import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../domain/models/user_settings.dart';
import '../view_models/settings_preferences_view_model.dart';
import 'widgets/settings_preference_scaffold.dart';

class DefaultViewScreen extends StatelessWidget {
  const DefaultViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsPreferencesViewModel>(
      builder: (context, viewModel, _) {
        return SettingsPreferenceScaffold(
          title: 'Default View',
          subtitle: 'Set starting layout on login',
          sectionLabel: 'STARTING DISPLAY MODE',
          saveLabel: 'Save View Preference',
          isSaving: viewModel.isSaving,
          onSave: () => _save(context, viewModel),
          child: SettingsSelectionCard(
            children: [
              _tile(
                viewModel,
                DefaultViewType.map,
                'Map',
                'Interactive spatial overhead facility mapping',
                Icons.map_outlined,
                AppColors.primaryBlue,
                AppColors.blueSoftTint,
              ),
              _tile(
                viewModel,
                DefaultViewType.list,
                'List',
                'Chronological scroll of all BaitGuard monitors',
                Icons.format_list_bulleted,
                AppColors.purple,
                AppColors.purpleTint,
              ),
              _tile(
                viewModel,
                DefaultViewType.grid,
                'Grid',
                'High density dashboard analytics grid layout',
                Icons.grid_on,
                AppColors.warningAmber,
                AppColors.amberTint,
              ),
            ],
          ),
        );
      },
    );
  }

  SettingsSelectionTile _tile(
    SettingsPreferencesViewModel viewModel,
    DefaultViewType value,
    String title,
    String description,
    IconData icon,
    Color iconColor,
    Color background,
  ) {
    return SettingsSelectionTile(
      key: ValueKey('defaultView_${value.name}'),
      title: title,
      description: description,
      icon: icon,
      iconColor: iconColor,
      iconBackground: background,
      selected: viewModel.selectedView == value,
      onTap: () => viewModel.selectView(value),
    );
  }

  Future<void> _save(
    BuildContext context,
    SettingsPreferencesViewModel viewModel,
  ) async {
    final settings = await viewModel.saveView();
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
