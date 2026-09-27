import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../domain/models/register_station_request.dart';
import '../view_models/add_station_view_model.dart';
import '../view_models/stations_view_model.dart';

class AddStationScreen extends StatefulWidget {
  const AddStationScreen({super.key});

  @override
  State<AddStationScreen> createState() => _AddStationScreenState();
}

class _AddStationScreenState extends State<AddStationScreen> {
  late int _lastSubmissionEventId;

  @override
  void initState() {
    super.initState();
    final vm = context.read<AddStationViewModel>();
    _lastSubmissionEventId = vm.submissionEventId;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddStationViewModel>();

    // Handle submission events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (vm.submissionEventId != _lastSubmissionEventId) {
        _lastSubmissionEventId = vm.submissionEventId;
        if (vm.isSuccess) {
          AppTopToast.show(context, '${vm.stationId} registered successfully.');

          // Optionally refresh StationsViewModel if accessible via parent context
          // but typically we can do this through the parent shell.
          // Since the prompt says "Reload or update StationsViewModel", we can try to
          // read it from context if it's available. The root navigator holds the StationsViewModel
          // in UserAppShell / AdminAppShell? Actually, StationsViewModel is provided above the shell!
          // So we can read it.
          try {
            final stationsVm = Provider.of<StationsViewModel>(
              context,
              listen: false,
            );
            stationsVm.clearSearchAndFilter();
            stationsVm.refresh(); // Or load
          } catch (_) {
            // Ignore if not found
          }

          Navigator.of(context).pop();
        } else if (vm.submissionErrorMessage != null) {
          AppTopToast.show(context, vm.submissionErrorMessage!);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStationInfoCard(vm),
                    const SizedBox(height: AppSpacing.lg),
                    _buildConnectivityCard(vm),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAlertsCard(vm),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildBottomAction(vm),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Add Station',
            style: AppTypography.manropeBold.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationInfoCard(AddStationViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Station Information',
            style: AppTypography.manropeBold.copyWith(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            label: 'Station ID',
            hint: 'e.g., RB-08',
            errorText: vm.stationIdError,
            onChanged: vm.setStationId,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            label: 'Station Name',
            hint: 'Enter station name',
            errorText: vm.stationNameError,
            onChanged: vm.setStationName,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Site / Facility',
            style: AppTypography.manropeSemiBold.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: vm.siteIdError != null
                    ? AppColors.criticalRed
                    : AppColors.borderSecondary,
              ),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: vm.selectedSiteId,
                hint: Text(
                  'Select Site / Facility',
                  style: AppTypography.manropeRegular.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 15,
                  ),
                ),
                isExpanded: true,
                items: vm.availableSites.map((site) {
                  return DropdownMenuItem<String>(
                    value: site.id,
                    child: Text(
                      site.name,
                      style: AppTypography.manropeRegular.copyWith(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: vm.setSelectedSiteId,
              ),
            ),
          ),
          if (vm.siteIdError != null) ...[
            const SizedBox(height: 4),
            Text(
              vm.siteIdError!,
              style: AppTypography.manropeRegular.copyWith(
                fontSize: 12,
                color: AppColors.criticalRed,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            label: 'Zone / Location',
            hint: 'Enter location description',
            errorText: vm.zoneLocationError,
            onChanged: vm.setZoneLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String? errorText,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.manropeSemiBold.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          onChanged: onChanged,
          style: AppTypography.manropeRegular.copyWith(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.manropeRegular.copyWith(
              color: AppColors.textTertiary,
              fontSize: 15,
            ),
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.borderSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.borderSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.criticalRed),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectivityCard(AddStationViewModel vm) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connectivity',
              style: AppTypography.manropeBold.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            RadioGroup<StationConnectivityType>(
              groupValue: vm.connectivityType,
              onChanged: (val) {
                if (val != null) {
                  vm.setConnectivityType(val);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRadioOption(
                    label: 'Wi-Fi (Recommended)',
                    value: StationConnectivityType.wifi,
                  ),
                  if (vm.connectivityType == StationConnectivityType.wifi)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 32.0,
                        bottom: AppSpacing.sm,
                        top: 4,
                      ),
                      child: _buildTextField(
                        label: 'Network Name',
                        hint: 'Enter Wi-Fi network name',
                        errorText: vm.wifiNetworkNameError,
                        onChanged: vm.setWifiNetworkName,
                      ),
                    ),
                  _buildRadioOption(
                    label: '4G / LTE',
                    value: StationConnectivityType.cellular,
                  ),
                  _buildRadioOption(
                    label: 'LoRaWAN',
                    value: StationConnectivityType.lorawan,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required StationConnectivityType value,
  }) {
    return RadioListTile<StationConnectivityType>(
      title: Text(
        label,
        style: AppTypography.manropeRegular.copyWith(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
      value: value,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primaryBlue,
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
    );
  }

  Widget _buildAlertsCard(AddStationViewModel vm) {
    final prefs = vm.alertPreferences;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert Notifications',
            style: AppTypography.manropeBold.copyWith(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSwitchOption(
            label: 'Rodent detection',
            value: prefs.rodentDetection,
            onChanged: (val) => vm.setAlertPreferences(
              StationAlertPreferences(
                rodentDetection: val,
                lowBait: prefs.lowBait,
                tamper: prefs.tamper,
                stationOffline: prefs.stationOffline,
              ),
            ),
          ),
          _buildSwitchOption(
            label: 'Low bait level',
            value: prefs.lowBait,
            onChanged: (val) => vm.setAlertPreferences(
              StationAlertPreferences(
                rodentDetection: prefs.rodentDetection,
                lowBait: val,
                tamper: prefs.tamper,
                stationOffline: prefs.stationOffline,
              ),
            ),
          ),
          _buildSwitchOption(
            label: 'Tamper alert',
            value: prefs.tamper,
            onChanged: (val) => vm.setAlertPreferences(
              StationAlertPreferences(
                rodentDetection: prefs.rodentDetection,
                lowBait: prefs.lowBait,
                tamper: val,
                stationOffline: prefs.stationOffline,
              ),
            ),
          ),
          _buildSwitchOption(
            label: 'Station offline',
            value: prefs.stationOffline,
            onChanged: (val) => vm.setAlertPreferences(
              StationAlertPreferences(
                rodentDetection: prefs.rodentDetection,
                lowBait: prefs.lowBait,
                tamper: prefs.tamper,
                stationOffline: val,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchOption({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.manropeRegular.copyWith(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryBlue,
            inactiveTrackColor: AppColors.borderSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(AddStationViewModel vm) {
    return ElevatedButton(
      onPressed: vm.isSubmitting ? null : vm.submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.divider,
        disabledForegroundColor: AppColors.textTertiary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        elevation: 0,
      ),
      child: vm.isSubmitting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Register Station',
              style: AppTypography.manropeBold.copyWith(fontSize: 16),
            ),
    );
  }
}
