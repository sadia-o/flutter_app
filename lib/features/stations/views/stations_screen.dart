import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../core/widgets/app_top_toast.dart';
import '../models/station_list_filter.dart';
import '../view_models/stations_view_model.dart';
import '../widgets/featured_station_card.dart';
import '../widgets/station_list_card.dart';

/// Screen 08 — Stations
///
/// Displays the station list for the currently selected facility.
/// Receives its ViewModel from the parent shell via Provider — never
/// instantiates or creates StationsViewModel itself.
/// when Screen 09 (Station Detail) is implemented. Use onStationTap(stationId),
/// onCameraTap(stationId, section: 'camera'), and onViewHistory(stationId,
/// section: 'activity') to pass the stable ID and preferred section.
class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  final _listCardKey = GlobalKey();
  final _searchController = TextEditingController();
  late int _lastRefreshErrorId;
  late int _lastActionEventId;

  @override
  void initState() {
    super.initState();
    final vm = context.read<StationsViewModel>();
    _lastRefreshErrorId = vm.refreshErrorEventId;
    _lastActionEventId = vm.actionEventId;
    _searchController.text = vm.searchQuery;

    // Load if not yet loaded.
    if (vm.status == StationsLoadStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => vm.load());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<StationsViewModel>(
          builder: (context, vm, _) {
            // Handle one-time events
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (vm.refreshErrorEventId != _lastRefreshErrorId) {
                _lastRefreshErrorId = vm.refreshErrorEventId;
                AppTopToast.show(
                  context,
                  vm.refreshErrorMessage ?? 'Refresh failed.',
                );
              }
              if (vm.actionEventId != _lastActionEventId) {
                _lastActionEventId = vm.actionEventId;
                AppTopToast.show(
                  context,
                  vm.actionMessage ?? 'Action completed.',
                );
              }
            });

            if (vm.status == StationsLoadStatus.initial ||
                vm.status == StationsLoadStatus.loading &&
                    vm.allStations.isEmpty) {
              return const AppLoadingState(message: 'Loading stations…');
            }

            if (vm.status == StationsLoadStatus.failure &&
                vm.allStations.isEmpty) {
              return AppErrorState(
                message: vm.errorMessage ?? 'Could not load stations.',
                onRetry: vm.load,
              );
            }

            return RefreshIndicator(
              onRefresh: vm.refresh,
              color: AppColors.primaryBlue,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ────────────────────────────────────
                          _buildHeader(context, vm),
                          const SizedBox(height: AppSpacing.md),

                          // ── Search ────────────────────────────────────
                          _buildSearchField(context, vm),
                          const SizedBox(height: AppSpacing.sm),

                          // ── Filter chips ──────────────────────────────
                          _buildFilterChips(vm),
                          const SizedBox(height: AppSpacing.md),

                          // ── Featured station ──────────────────────────
                          if (vm.featuredStation != null)
                            FeaturedStationCard(
                              overview: vm.featuredStation!,
                              permissions: vm.permissions,
                              isRefilling: vm.isMutating(
                                vm.featuredStation!.station.id,
                              ),
                              isSilencing: vm.isMutating(
                                vm.featuredStation!.station.id,
                              ),
                              onStationTap: (id) => _onStationTap(context, id),
                              onCameraTap: (id) => _onCameraTap(context, id),
                              onViewHistory: (id) =>
                                  _onViewHistory(context, id),
                              onLocate: (id) => _onLocate(context, id),
                              onRefill: (id) => _confirmRefill(context, vm, id),
                              onSilence: (id) => vm.toggleSilenceStation(id),
                            )
                          else if (vm.status == StationsLoadStatus.success &&
                              vm.allStations.isNotEmpty)
                            _buildNoResultsState(context, vm),

                          const SizedBox(height: AppSpacing.md),

                          // ── All stations list ──────────────────────────
                          if (vm.allStations.isNotEmpty)
                            SizedBox(
                              key: _listCardKey,
                              child: StationListCard(
                                stations: vm.filteredStations,
                                onStationTap: (id) =>
                                    _onStationTap(context, id),
                                onSeeAll: () => _onSeeAll(vm),
                              ),
                            )
                          else if (vm.status == StationsLoadStatus.success)
                            _buildFacilityEmptyState(),

                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, StationsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stations',
                  style: AppTypography.manropeExtraBold.copyWith(
                    fontSize: 28,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vm.totalCount} total · ${vm.activeCount} active',
                  style: AppTypography.manropeRegular.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (vm.permissions.canAddStation)
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/add'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
        ],
      ),
    );
  }

  // ── Search field ─────────────────────────────────────────────────────────────

  Widget _buildSearchField(BuildContext context, StationsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.md),
            const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: vm.setSearchQuery,
                style: AppTypography.manropeRegular.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search stations, location',
                  hintStyle: AppTypography.manropeRegular.copyWith(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (vm.searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  vm.setSearchQuery('');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            GestureDetector(
              onTap: () => AppTopToast.show(
                context,
                'Advanced station filters will be available shortly.',
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Icon(
                  Icons.tune_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────────────

  Widget _buildFilterChips(StationsViewModel vm) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _FilterChip(
            label: 'All',
            dotColor: AppColors.primaryBlue,
            isSelected: vm.selectedFilter == StationListFilter.all,
            onTap: () => vm.setFilter(StationListFilter.all),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Alerts',
            dotColor: AppColors.criticalRed,
            isSelected: vm.selectedFilter == StationListFilter.alerts,
            onTap: () => vm.setFilter(StationListFilter.alerts),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Low bait',
            dotColor: AppColors.warningAmber,
            isSelected: vm.selectedFilter == StationListFilter.lowBait,
            onTap: () => vm.setFilter(StationListFilter.lowBait),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Online',
            dotColor: AppColors.successGreen,
            isSelected: vm.selectedFilter == StationListFilter.online,
            onTap: () => vm.setFilter(StationListFilter.online),
          ),
        ],
      ),
    );
  }

  // ── Empty states ─────────────────────────────────────────────────────────────

  Widget _buildNoResultsState(BuildContext context, StationsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No stations match your search or filter.',
              textAlign: TextAlign.center,
              style: AppTypography.manropeRegular.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                vm.clearSearchAndFilter();
              },
              child: Text(
                'Clear search',
                style: AppTypography.manropeSemiBold.copyWith(
                  fontSize: 14,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 56,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No stations are available for this facility.',
              textAlign: TextAlign.center,
              style: AppTypography.manropeRegular.copyWith(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Interaction handlers ──────────────────────────────────────────────────────

  void _onStationTap(BuildContext context, String stationId) {
    Navigator.of(context).pushNamed('/detail/$stationId');
  }

  void _onCameraTap(BuildContext context, String stationId) {
    Navigator.of(context).pushNamed('/detail/$stationId');
  }

  void _onViewHistory(BuildContext context, String stationId) {
    Navigator.of(context).pushNamed('/detail/$stationId');
  }

  void _onLocate(BuildContext context, String stationId) {
    AppTopToast.show(context, 'Station location will be available shortly.');
  }

  void _onSeeAll(StationsViewModel vm) {
    _searchController.clear();
    vm.clearSearchAndFilter();

    // Scroll to the list card when safe.
    final ctx = _listCardKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _confirmRefill(
    BuildContext context,
    StationsViewModel vm,
    String stationId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Confirm Refill',
          style: AppTypography.manropeBold.copyWith(
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Mark $stationId as refilled and set bait level to 100%?',
          style: AppTypography.manropeRegular.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Refill',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await vm.refillStation(stationId);
    }
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final Color dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.dotColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: label,
        selected: isSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSelected) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTypography.manropeSemiBold.copyWith(
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
