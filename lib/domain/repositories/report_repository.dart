import '../models/report_models.dart';

abstract class ReportRepository {
  Future<ReportsDashboardData> getDashboardData({
    required String siteId,
    required ReportPeriod period,
  });

  Future<ReportExport> generateReport(ReportGenerationRequest request);

  Future<List<ReportExport>> getRecentExports({required String siteId});

  /// Reactive stream for live report updates
  Stream<ReportsDashboardData> watchDashboardData({
    required String siteId,
    required ReportPeriod period,
  }) => Stream.fromFuture(getDashboardData(siteId: siteId, period: period));

  /// Indicates whether the repository supports file exports
  bool get supportsExport => false;
}
