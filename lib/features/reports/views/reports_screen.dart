import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../domain/models/report_models.dart';
import '../../../../core/widgets/app_top_toast.dart';
import '../view_models/reports_view_model.dart';
import 'widgets/kpi_card.dart';
import 'widgets/reports_detection_trend_chart.dart';
import 'widgets/station_ledger_card.dart';
import 'widgets/generate_report_card.dart';
import 'widgets/recent_exports_card.dart';
import 'widgets/report_ready_modal.dart';

class ReportsScreen extends StatefulWidget {
  final void Function(String stationId)? onStationTap;

  const ReportsScreen({super.key, this.onStationTap});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _lastActionSuccessEventId = 0;
  int _lastActionErrorEventId = 0;
  int _lastRefreshErrorEventId = 0;

  late ReportsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<ReportsViewModel>();
    _lastActionSuccessEventId = _vm.actionSuccessEventId;
    _lastActionErrorEventId = _vm.actionErrorEventId;
    _lastRefreshErrorEventId = _vm.refreshErrorEventId;
    _vm.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    final vm = _vm;

    if (vm.actionSuccessEventId > _lastActionSuccessEventId) {
      _lastActionSuccessEventId = vm.actionSuccessEventId;
      if (vm.generatedExport != null &&
          vm.actionSuccessMessage == 'Report generated successfully.') {
        _showReportReadyModal(vm.generatedExport!);
      } else if (vm.actionSuccessMessage != null) {
        AppTopToast.show(context, vm.actionSuccessMessage!);
      }
    }

    if (vm.actionErrorEventId > _lastActionErrorEventId) {
      _lastActionErrorEventId = vm.actionErrorEventId;
      if (vm.actionErrorMessage != null) {
        AppTopToast.show(context, vm.actionErrorMessage!);
      }
    }

    if (vm.refreshErrorEventId > _lastRefreshErrorEventId) {
      _lastRefreshErrorEventId = vm.refreshErrorEventId;
      if (vm.refreshErrorMessage != null) {
        AppTopToast.show(context, vm.refreshErrorMessage!);
      }
    }
  }

  void _showReportReadyModal(ReportExport export) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ReportReadyModal(
        exportData: export,
        onDownload: () {
          _vm.handleMockDownload();
        },
        onShare: () {
          _vm.handleMockShare();
        },
        onDone: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showPeriodPicker(BuildContext context, ReportsViewModel vm) async {
    // This could be a complex date picker depending on the period.
    // For simplicity, we just use a standard date picker.
    final initialDate = vm.selectedPeriod.anchorDate;
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.purple,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (newDate != null) {
      vm.changeAnchorDate(newDate);
    }
  }

  Widget _buildPeriodSelector(ReportsViewModel vm) {
    final types = const [
      ReportPeriodType.week,
      ReportPeriodType.month,
      ReportPeriodType.quarter,
      ReportPeriodType.year,
    ];
    final labels = const ['Week', 'Month', 'Quarter', 'Year'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(types.length, (index) {
          final type = types[index];
          final isSelected = vm.selectedPeriod.type == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!vm.permissions.canChangePeriod) {
                  AppTopToast.show(context, 'Permission denied.');
                  return;
                }
                vm.changePeriodType(type);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: isSelected
                    ? BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      )
                    : null,
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: AppTypography.manropeMedium.copyWith(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = vm.dashboardData;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: vm.refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xxl,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reports',
                                  style: AppTypography.manropeBold.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Audits & compliance',
                                  style: AppTypography.manropeRegular.copyWith(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => _showPeriodPicker(context, vm),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: AppColors.purple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getPeriodButtonLabel(vm.selectedPeriod),
                                      style: AppTypography.manropeRegular
                                          .copyWith(fontSize: 14)
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (data == null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No report data is available for this period.',
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: vm.refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: _buildPeriodSelector(vm),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (vm.permissions.canViewSummary) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: KpiCard(
                                    label: 'Total detections',
                                    value: data.summary.totalDetections
                                        .toString(),
                                    changePercent:
                                        data.summary.detectionsChangePercent,
                                    positiveIsGood: false,
                                    valueColor: AppColors.criticalRed,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: KpiCard(
                                    label: 'Bait refills',
                                    value: data.summary.baitRefills != null
                                        ? data.summary.baitRefills.toString()
                                        : '—',
                                    changePercent:
                                        data.summary.baitRefillsChangePercent,
                                    positiveIsGood: true,
                                    valueColor: AppColors.warningAmber,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: KpiCard(
                                    label: 'System uptime',
                                    value:
                                        data.summary.systemUptimePercent != null
                                        ? '${data.summary.systemUptimePercent!.toStringAsFixed(1)}%'
                                        : '—',
                                    changePercent:
                                        data.summary.uptimeChangePercent,
                                    positiveIsGood: true,
                                    valueColor: AppColors.successGreen,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: KpiCard(
                                    label: 'AI confidence',
                                    value:
                                        data
                                                .summary
                                                .averageAiConfidencePercent !=
                                            null
                                        ? '${data.summary.averageAiConfidencePercent!.toStringAsFixed(0)}%'
                                        : '—',
                                    changePercent:
                                        data.summary.confidenceChangePercent,
                                    positiveIsGood: true,
                                    valueColor: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          if (vm.permissions.canGenerateMonthlyActivity ||
                              vm.permissions.canGenerateBaitConsumption ||
                              vm.permissions.canGenerateComplianceAudit) ...[
                            GenerateReportCard(
                              selectedPeriod: vm.selectedPeriod,
                              isGenerating: vm.isGenerating,
                              generatingTemplateType: vm.generatingTemplateType,
                              onGenerate: vm.generateReport,
                              permissions: vm.permissions,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          if (vm.permissions.canViewTrendChart) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.card,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detections trend',
                                    style: AppTypography.manropeSemiBold
                                        .copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  ReportsDetectionTrendChart(
                                    trend: data.detectionTrend,
                                    periodType: vm.selectedPeriod.type,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          if (vm.permissions.canViewStationLedger) ...[
                            StationLedgerCard(
                              entries: data.stationLedger,
                              onStationTap: vm.permissions.canOpenStationDetail
                                  ? widget.onStationTap
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          if (vm.permissions.canViewExistingExports) ...[
                            RecentExportsCard(
                              exports: data.recentExports,
                              onSeeAll: () {
                                Navigator.of(
                                  context,
                                ).pushNamed('/recent-exports');
                              },
                              onDownloadMock: vm.handleMockDownload,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                // Bottom safe space
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 80,
                  ), // To ensure content clears bottom nav
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPeriodButtonLabel(ReportPeriod period) {
    final date = period.anchorDate;
    switch (period.type) {
      case ReportPeriodType.week:
        return 'W${(date.day / 7).ceil()}'; // Simplification for mock
      case ReportPeriodType.month:
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return months[date.month - 1];
      case ReportPeriodType.quarter:
        return 'Q${((date.month - 1) ~/ 3) + 1}';
      case ReportPeriodType.year:
        return '${date.year}';
    }
  }
}
