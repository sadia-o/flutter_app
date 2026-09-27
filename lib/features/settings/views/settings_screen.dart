import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/navigation/route_names.dart';
import '../../../app/state/app_session_controller.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../app/state/auth_session_coordinator.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../../../domain/models/user_settings.dart';
import '../view_models/settings_view_model.dart';
import '../view_models/settings_preferences_view_model.dart';
import 'widgets/settings_action_tile.dart';
import 'widgets/settings_toggle_tile.dart';
import 'widgets/settings_profile_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _lastErrorId = 0;
  int _lastSuccessId = 0;
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<SettingsViewModel>();
    _lastErrorId = _viewModel.actionErrorEventId;
    _lastSuccessId = _viewModel.actionSuccessEventId;
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    final vm = context.read<SettingsViewModel>();
    if (vm.actionErrorEventId > _lastErrorId) {
      _lastErrorId = vm.actionErrorEventId;
      if (vm.actionErrorMessage != null) {
        AppTopToast.show(context, vm.actionErrorMessage!);
      }
    }
    if (vm.actionSuccessEventId > _lastSuccessId) {
      _lastSuccessId = vm.actionSuccessEventId;
      if (vm.actionSuccessMessage != null) {
        AppTopToast.show(context, vm.actionSuccessMessage!);
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    AuthSessionCoordinator? coordinator;
    try {
      coordinator = context.read<AuthSessionCoordinator>();
    } catch (_) {
      coordinator = null;
    }

    if (coordinator != null) {
      if (coordinator.isLoggingOut) return;
      final success = await coordinator.logout();
      if (!context.mounted) return;
      if (!success) {
        AppTopToast.show(
          context,
          coordinator.logoutErrorMessage ??
              'Unable to log out right now. Please try again.',
        );
        return;
      }
    } else {
      context.read<AppSessionController>().clearSession();
    }

    if (!context.mounted) return;
    final activeFacilityController = context.read<ActiveFacilityController>();
    activeFacilityController.resetToInitialFacility();
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(RouteNames.welcome, (route) => false);
  }

  Future<void> _openPreference(
    BuildContext context,
    SettingsViewModel viewModel,
    String routeName,
  ) async {
    final currentSettings = viewModel.settings;
    final currentUser = context.read<AppSessionController>().currentUser;
    if (currentSettings == null || currentUser == null) return;

    final result = await Navigator.of(context, rootNavigator: true).pushNamed(
      routeName,
      arguments: SettingsPreferencesRouteArguments(
        settings: currentSettings,
        permittedFacilityIds: currentUser.siteAccessIds,
      ),
    );
    if (!context.mounted || result is! UserSettings) return;

    await viewModel.applySavedSettings(result);
    if (!context.mounted) return;

    final message = switch (routeName) {
      RouteNames.defaultView =>
        'Default view changed to ${_formatViewType(result.defaultView)}',
      RouteNames.defaultFacility =>
        'Default facility changed to ${viewModel.activeFacilityName ?? 'selected facility'}',
      RouteNames.defaultAlertFilter =>
        'Default alert filter changed to ${_formatFilterType(result.defaultAlertFilter)}',
      _ => 'Preference updated',
    };
    AppTopToast.show(context, message);
  }

  Future<void> _openSettingsAction(
    BuildContext context,
    String routeName,
    String userId,
  ) async {
    final result = await Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(routeName, arguments: userId);
    if (!context.mounted || result is! String) return;
    AppTopToast.show(context, result);
  }

  String _formatViewType(DefaultViewType type) {
    switch (type) {
      case DefaultViewType.map:
        return 'Map';
      case DefaultViewType.list:
        return 'List';
      case DefaultViewType.grid:
        return 'Grid';
    }
  }

  String _formatFilterType(AlertFilterType type) {
    switch (type) {
      case AlertFilterType.all:
        return 'All Alerts';
      case AlertFilterType.rodent:
        return 'Rodent Only';
      case AlertFilterType.lowBait:
        return 'Low Bait Only';
      case AlertFilterType.tamper:
        return 'Tamper Only';
      case AlertFilterType.offline:
        return 'Offline Only';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionUser = context.watch<AppSessionController>().currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<SettingsViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading || vm.settings == null || sessionUser == null) {
              return const AppLoadingState(message: 'Loading settings...');
            }

            final user = sessionUser;
            final settings = vm.settings!;
            final prefs = settings.notifications;

            // Resolve actual facility name if available, fallback to None
            final facilityName = vm.activeFacilityName ?? 'None';

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          // Header Row with Back Button
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.lg,
                                    ),
                                    border: Border.all(
                                      color: AppColors.borderSecondary,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: AppColors.textPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Settings',
                                      style: AppTypography.manropeBold.copyWith(
                                        fontSize: 24,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Manage your account and preferences',
                                      style: AppTypography.manropeRegular
                                          .copyWith(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Profile Card
                          SettingsProfileCard(
                            user: user,
                            activeFacilityName: facilityName,
                            onEditTap: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamed(
                                RouteNames.editProfile,
                                arguments: facilityName,
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Notification Preferences Section
                          _buildSectionHeader('Notifications'),
                          _buildCard([
                            SettingsToggleTile(
                              title: 'Rodent Detection Alerts',
                              subtitle:
                                  'Instant push when rodents are verified',
                              leadingIcon: Icons.pest_control,
                              iconColor: AppColors.criticalRed,
                              iconBackgroundColor: AppColors.redTint,
                              value: prefs.rodentAlerts,
                              onChanged: (val) => vm.updateNotifications(
                                prefs.copyWith(rodentAlerts: val),
                                'Rodent detection alerts',
                                val,
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SettingsToggleTile(
                              title: 'Low Bait Alerts',
                              subtitle:
                                  'Notify when bait blocks drop below 20%',
                              leadingIcon: Icons.warning_amber_rounded,
                              iconColor: AppColors.warningAmber,
                              iconBackgroundColor: AppColors.amberTint,
                              value: prefs.lowBaitAlerts,
                              onChanged: (val) => vm.updateNotifications(
                                prefs.copyWith(lowBaitAlerts: val),
                                'Low bait alerts',
                                val,
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SettingsToggleTile(
                              title: 'Tamper Alerts',
                              subtitle: 'Alert if station is moved or opened',
                              leadingIcon: Icons.vibration,
                              iconColor: AppColors.primaryBlue,
                              iconBackgroundColor: AppColors.blueTint,
                              value: prefs.tamperAlerts,
                              onChanged: (val) => vm.updateNotifications(
                                prefs.copyWith(tamperAlerts: val),
                                'Tamper alerts',
                                val,
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SettingsToggleTile(
                              title: 'Station Offline Alerts',
                              subtitle: 'Notify if a station drops connection',
                              leadingIcon: Icons.wifi_off,
                              iconColor: AppColors.textTertiary,
                              iconBackgroundColor: AppColors.borderSecondary
                                  .withValues(alpha: 0.2),
                              value: prefs.stationOfflineAlerts,
                              onChanged: (val) => vm.updateNotifications(
                                prefs.copyWith(stationOfflineAlerts: val),
                                'Station offline alerts',
                                val,
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SettingsToggleTile(
                              title: 'Push Notifications',
                              subtitle: 'Receive system alerts on this device',
                              leadingIcon: Icons.notifications_active,
                              iconColor: AppColors.purple,
                              iconBackgroundColor: AppColors.purpleTint,
                              value: prefs.pushAlerts,
                              onChanged: (val) => vm.updateNotifications(
                                prefs.copyWith(pushAlerts: val),
                                'Push notifications',
                                val,
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SettingsToggleTile(
                              title: 'Email Notifications',
                              subtitle:
                                  'Receive daily digests and major alerts via email',
                              leadingIcon: Icons.email,
                              iconColor: AppColors.emerald,
                              iconBackgroundColor: AppColors.greenTint,
                              value: prefs.emailAlerts,
                              onChanged: (val) => vm.updateNotifications(
                                prefs.copyWith(emailAlerts: val),
                                'Email notifications',
                                val,
                              ),
                            ),
                          ]),
                          const SizedBox(height: AppSpacing.xl),

                          // Station Preferences Section
                          _buildSectionHeader('Preferences'),
                          _buildCard([
                            SettingsActionTile(
                              title: 'Default Facility',
                              subtitle: 'The facility selected on app launch',
                              leadingIcon: Icons.business,
                              iconColor: AppColors.primaryBlue,
                              iconBackgroundColor: AppColors.blueTint,
                              valueText:
                                  facilityName, // Display actual name, not site_1
                              onTap: () => _openPreference(
                                context,
                                vm,
                                RouteNames.defaultFacility,
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SettingsActionTile(
                              title: 'Default View',
                              subtitle: 'How stations are displayed',
                              leadingIcon: Icons.view_comfortable,
                              iconColor: AppColors.purple,
                              iconBackgroundColor: AppColors.purpleTint,
                              valueText: _formatViewType(settings.defaultView),
                              onTap: () => _openPreference(
                                context,
                                vm,
                                RouteNames.defaultView,
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SettingsActionTile(
                              title: 'Default Alert Filter',
                              subtitle:
                                  'Default visible alert types on dashboard',
                              leadingIcon: Icons.filter_list,
                              iconColor: AppColors.warningAmber,
                              iconBackgroundColor: AppColors.amberTint,
                              valueText: _formatFilterType(
                                settings.defaultAlertFilter,
                              ),
                              onTap: () => _openPreference(
                                context,
                                vm,
                                RouteNames.defaultAlertFilter,
                              ),
                            ),
                          ]),
                          const SizedBox(height: AppSpacing.xl),

                          // Account Section
                          _buildSectionHeader('Security & Support'),
                          _buildCard([
                            SettingsActionTile(
                              title: 'Change Password',
                              leadingIcon: Icons.lock_outline,
                              iconColor: AppColors.textSecondary,
                              iconBackgroundColor: AppColors.borderSecondary
                                  .withValues(alpha: 0.2),
                              onTap: () => _openSettingsAction(
                                context,
                                RouteNames.changePassword,
                                user.id,
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SettingsActionTile(
                              title: 'Contact Administrator',
                              subtitle:
                                  'Questions or issues with your account?',
                              leadingIcon: Icons.support_agent,
                              iconColor: AppColors.primaryBlue,
                              iconBackgroundColor: AppColors.blueTint,
                              onTap: () => _openSettingsAction(
                                context,
                                RouteNames.contactAdministrator,
                                user.id,
                              ),
                            ),
                          ]),
                          const SizedBox(height: AppSpacing.xl),

                          // About Section
                          _buildSectionHeader('About'),
                          _buildCard([
                            SettingsActionTile(
                              title: 'Smart BaitGuard',
                              subtitle: 'Version 1.0.0 (Build 42)',
                              leadingIcon: Icons.info_outline,
                              iconColor: AppColors.emerald,
                              iconBackgroundColor: AppColors.greenTint,
                              showChevron: false,
                              trailingWidget: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.greenTint,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                ),
                                child: Text(
                                  'Up to date',
                                  style: AppTypography.manropeBold.copyWith(
                                    fontSize: 12,
                                    color: AppColors.alternateSuccess,
                                  ),
                                ),
                              ),
                              onTap: () {},
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SettingsActionTile(
                              title: 'Privacy Policy',
                              leadingIcon: Icons.privacy_tip_outlined,
                              iconColor: AppColors.textSecondary,
                              iconBackgroundColor: AppColors.borderSecondary
                                  .withValues(alpha: 0.2),
                              onTap: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamed(RouteNames.privacyPolicy),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SettingsActionTile(
                              title: 'Terms & Conditions',
                              leadingIcon: Icons.description_outlined,
                              iconColor: AppColors.textSecondary,
                              iconBackgroundColor: AppColors.borderSecondary
                                  .withValues(alpha: 0.2),
                              onTap: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamed(RouteNames.termsConditions),
                            ),
                          ]),
                          const SizedBox(height: AppSpacing.xl),

                          // Logout Button
                          _buildCard([
                            SettingsActionTile(
                              title: 'Log Out',
                              leadingIcon: Icons.logout,
                              iconColor: AppColors.criticalRed,
                              iconBackgroundColor: AppColors.redTint,
                              isDestructive: true,
                              destructiveColor: AppColors.criticalRed,
                              showChevron: false,
                              onTap: () => _handleLogout(context),
                            ),
                          ]),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.interBold.copyWith(
          fontSize: 12,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }
}
