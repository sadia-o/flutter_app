import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../domain/models/settings_facility_option.dart';
import '../view_models/settings_preferences_view_model.dart';
import 'widgets/settings_preference_scaffold.dart';

class DefaultFacilityScreen extends StatefulWidget {
  const DefaultFacilityScreen({super.key});

  @override
  State<DefaultFacilityScreen> createState() => _DefaultFacilityScreenState();
}

class _DefaultFacilityScreenState extends State<DefaultFacilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SettingsPreferencesViewModel>().loadFacilities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsPreferencesViewModel>(
      builder: (context, viewModel, _) {
        return SettingsPreferenceScaffold(
          title: 'Default Facility',
          subtitle: 'Configure primary monitored area',
          sectionLabel: 'MONITORED FACILITIES',
          saveLabel: 'Save Changes',
          isSaving: viewModel.isSaving,
          onSave: viewModel.isLoadingFacilities || viewModel.facilities.isEmpty
              ? null
              : () => _save(context, viewModel),
          child: viewModel.isLoadingFacilities
              ? const AppLoadingState(message: 'Loading facilities...')
              : SettingsSelectionCard(
                  children: viewModel.facilities
                      .map((facility) => _tile(viewModel, facility))
                      .toList(),
                ),
        );
      },
    );
  }

  SettingsSelectionTile _tile(
    SettingsPreferencesViewModel viewModel,
    SettingsFacilityOption facility,
  ) {
    final healthy = facility.isHealthy;
    return SettingsSelectionTile(
      key: ValueKey('facility_${facility.id}'),
      title: facility.name,
      description: '${facility.stationCount} active monitoring stations',
      icon: Icons.business,
      iconColor: AppColors.primaryBlue,
      iconBackground: AppColors.blueSoftTint,
      selected: viewModel.selectedFacilityId == facility.id,
      onTap: () => viewModel.selectFacility(facility.id),
      status: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: healthy ? AppColors.greenTint : AppColors.redTint,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          healthy ? 'Healthy' : '${facility.offlineStationCount} Offline',
          style: AppTypography.manropeSemiBold.copyWith(
            fontSize: 10,
            color: healthy ? AppColors.successGreen : AppColors.criticalRed,
          ),
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    SettingsPreferencesViewModel viewModel,
  ) async {
    final settings = await viewModel.saveFacility();
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
