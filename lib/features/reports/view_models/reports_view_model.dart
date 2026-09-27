import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../app/state/active_facility_controller.dart';
import '../../../domain/models/report_models.dart';
import '../../../domain/repositories/report_repository.dart';
import '../../../domain/models/user_role.dart';
import '../models/reports_permissions.dart';

class ReportsViewModel extends ChangeNotifier {
  final ReportRepository _repository;
  final ActiveFacilityController _activeFacilityController;
  final ReportsPermissions permissions;
  final String currentUserId;

  ReportsViewModel({
    required ReportRepository repository,
    required ActiveFacilityController activeFacilityController,
    required UserRole userRole,
    required this.currentUserId,
  }) : _repository = repository,
       _activeFacilityController = activeFacilityController,
       permissions = ReportsPermissions.fromRole(
         userRole,
         supportsExport: repository.supportsExport,
       ) {
    _activeFacilityController.addListener(_onFacilityChanged);
    _loadData();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  ReportsDashboardData? _dashboardData;
  ReportsDashboardData? get dashboardData => _dashboardData;

  ReportPeriod _selectedPeriod = ReportPeriod(
    type: ReportPeriodType.month,
    anchorDate: DateTime.now(),
  );
  ReportPeriod get selectedPeriod => _selectedPeriod;

  // Report Generation State
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  ReportTemplateType? _generatingTemplateType;
  ReportTemplateType? get generatingTemplateType => _generatingTemplateType;

  // Event pattern
  int actionSuccessEventId = 0;
  String? actionSuccessMessage;

  int actionErrorEventId = 0;
  String? actionErrorMessage;

  int refreshErrorEventId = 0;
  String? refreshErrorMessage;

  ReportExport? generatedExport;
  StreamSubscription<ReportsDashboardData>? _reportsSub;

  @override
  void dispose() {
    _reportsSub?.cancel();
    _reportsSub = null;
    _activeFacilityController.removeListener(_onFacilityChanged);
    super.dispose();
  }

  void _onFacilityChanged() {
    // Reload when facility changes
    _loadData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _loadData() async {
    final siteId = _activeFacilityController.selectedSiteId;
    if (siteId == null) return; // No active facility

    _setLoading(true);

    _reportsSub?.cancel();
    _reportsSub = _repository
        .watchDashboardData(siteId: siteId, period: _selectedPeriod)
        .listen(
          (data) {
            _dashboardData = data;
            _setLoading(false);
          },
          onError: (e) {
            _triggerRefreshError('Reports could not be refreshed.');
            _setLoading(false);
          },
        );
  }

  Future<void> refresh() async {
    final siteId = _activeFacilityController.selectedSiteId;
    if (siteId == null) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      _dashboardData = await _repository.getDashboardData(
        siteId: siteId,
        period: _selectedPeriod,
      );
    } catch (e) {
      _triggerRefreshError('Reports could not be refreshed.');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void changePeriodType(ReportPeriodType newType) {
    if (_selectedPeriod.type == newType) return;
    _selectedPeriod = ReportPeriod(type: newType, anchorDate: DateTime.now());
    _loadData();
  }

  void changeAnchorDate(DateTime newDate) {
    _selectedPeriod = ReportPeriod(
      type: _selectedPeriod.type,
      anchorDate: newDate,
    );
    _loadData();
  }

  Future<void> generateReport(ReportTemplateType templateType) async {
    if (_isGenerating) return;
    if (!_repository.supportsExport) {
      _triggerActionError('Report export is unavailable in this pilot.');
      return;
    }
    if (!permissions.canGenerateTemplate(templateType)) {
      _triggerActionError('Permission denied to generate this report.');
      return;
    }

    final siteId = _activeFacilityController.selectedSiteId;
    if (siteId == null) {
      _triggerActionError('No active facility selected.');
      return;
    }

    _isGenerating = true;
    _generatingTemplateType = templateType;
    notifyListeners();

    try {
      final export = await _repository.generateReport(
        ReportGenerationRequest(
          siteId: siteId,
          generatedByUserId: currentUserId,
          templateType: templateType,
          period: _selectedPeriod,
        ),
      );

      generatedExport = export;

      // Update local exports list to match what was generated
      if (_dashboardData != null) {
        final newExports = List<ReportExport>.from(
          _dashboardData!.recentExports,
        );
        newExports.insert(0, export);
        _dashboardData = ReportsDashboardData(
          summary: _dashboardData!.summary,
          detectionTrend: _dashboardData!.detectionTrend,
          stationLedger: _dashboardData!.stationLedger,
          recentExports: newExports,
        );
      }

      _triggerActionSuccess('Report generated successfully.');
    } catch (e) {
      _triggerActionError('Report could not be generated. Please try again.');
    } finally {
      _isGenerating = false;
      _generatingTemplateType = null;
      notifyListeners();
    }
  }

  void handleMockDownload() {
    if (!_repository.supportsExport || !permissions.canDownloadMock) {
      _triggerActionError('Report download is unavailable in this pilot.');
      return;
    }
    _triggerActionError(
      'Report download will be available after Firebase integration.',
    );
  }

  void handleMockShare() {
    if (!_repository.supportsExport || !permissions.canShareMock) {
      _triggerActionError('Report sharing is unavailable in this pilot.');
      return;
    }
    _triggerActionError(
      'Report sharing will be available after Firebase integration.',
    );
  }

  void _triggerActionSuccess(String message) {
    actionSuccessMessage = message;
    actionSuccessEventId++;
    notifyListeners();
  }

  void _triggerActionError(String message) {
    actionErrorMessage = message;
    actionErrorEventId++;
    notifyListeners();
  }

  void _triggerRefreshError(String message) {
    refreshErrorMessage = message;
    refreshErrorEventId++;
    notifyListeners();
  }
}
