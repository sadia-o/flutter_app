import '../../../domain/models/user_role.dart';
import '../../../domain/models/report_models.dart';

class ReportsPermissions {
  final bool canViewSummary;
  final bool canChangePeriod;
  final bool canViewTrendChart;
  final bool canViewStationLedger;
  final bool canViewExistingExports;
  final bool canOpenStationDetail;
  final bool canDownloadMock;
  final bool canShareMock;
  final bool canGenerateMonthlyActivity;
  final bool canGenerateBaitConsumption;
  final bool canGenerateComplianceAudit;

  const ReportsPermissions({
    this.canViewSummary = true,
    this.canChangePeriod = true,
    this.canViewTrendChart = true,
    this.canViewStationLedger = true,
    this.canViewExistingExports = true,
    this.canOpenStationDetail = true,
    this.canDownloadMock = true,
    this.canShareMock = true,
    this.canGenerateMonthlyActivity = false,
    this.canGenerateBaitConsumption = false,
    this.canGenerateComplianceAudit = false,
  });

  factory ReportsPermissions.fromRole(
    UserRole role, {
    bool supportsExport = true,
  }) {
    if (!supportsExport) {
      return const ReportsPermissions(
        canViewSummary: true,
        canChangePeriod: true,
        canViewTrendChart: true,
        canViewStationLedger: true,
        canViewExistingExports: false,
        canOpenStationDetail: true,
        canDownloadMock: false,
        canShareMock: false,
        canGenerateMonthlyActivity: false,
        canGenerateBaitConsumption: false,
        canGenerateComplianceAudit: false,
      );
    }
    switch (role) {
      case UserRole.admin:
        return const ReportsPermissions(
          canGenerateMonthlyActivity: true,
          canGenerateBaitConsumption: true,
          canGenerateComplianceAudit: true,
        );
      case UserRole.technician:
        return const ReportsPermissions(
          canGenerateMonthlyActivity: true,
          canGenerateBaitConsumption: true,
          canGenerateComplianceAudit: false,
        );
      case UserRole.viewer:
        return const ReportsPermissions(
          canGenerateMonthlyActivity: false,
          canGenerateBaitConsumption: false,
          canGenerateComplianceAudit: false,
          // Share is not allowed for viewer according to prompt?
          // Wait, the prompt says "Viewer Can: use mock Download". It doesn't mention Share.
          canShareMock: false,
        );
    }
  }

  bool canGenerateTemplate(ReportTemplateType type) {
    switch (type) {
      case ReportTemplateType.monthlyActivity:
        return canGenerateMonthlyActivity;
      case ReportTemplateType.baitConsumption:
        return canGenerateBaitConsumption;
      case ReportTemplateType.complianceAudit:
        return canGenerateComplianceAudit;
    }
  }
}
