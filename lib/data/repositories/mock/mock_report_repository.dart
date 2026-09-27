import '../../../domain/models/report_models.dart';
import '../../../domain/repositories/report_repository.dart';
import 'mock_baitguard_data_source.dart';

class MockReportRepository implements ReportRepository {
  final MockBaitGuardDataSource _dataSource;

  MockReportRepository(this._dataSource);

  @override
  Future<ReportsDashboardData> getDashboardData({
    required String siteId,
    required ReportPeriod period,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // We generate deterministic mock data based on period type and siteId
    final isWeek = period.type == ReportPeriodType.week;
    final isQuarter = period.type == ReportPeriodType.quarter;
    final isYear = period.type == ReportPeriodType.year;

    // Base values that look like the Figma (month)
    int baseDetections = 87;
    int baseRefills = 34;
    double baseUptime = 99.1;
    double baseConf = 96.0;

    // Tweak based on period to make them coherent but different
    if (isWeek) {
      baseDetections = 21;
      baseRefills = 8;
      baseUptime = 99.5;
      baseConf = 97.2;
    } else if (isQuarter) {
      baseDetections = 254;
      baseRefills = 98;
      baseUptime = 98.7;
      baseConf = 95.8;
    } else if (isYear) {
      baseDetections = 1045;
      baseRefills = 380;
      baseUptime = 98.2;
      baseConf = 94.5;
    }

    // Tweak slightly based on siteId for variety
    final siteHash = siteId.hashCode;
    final siteModifier = (siteHash % 10) / 10.0;

    final summary = ReportSummary(
      totalDetections: (baseDetections * (1 + siteModifier)).round(),
      baitRefills: (baseRefills * (1 + siteModifier)).round(),
      systemUptimePercent: (baseUptime - siteModifier).clamp(0, 100),
      averageAiConfidencePercent: (baseConf - siteModifier).clamp(0, 100),
      detectionsChangePercent: isWeek ? -5.0 : 12.0,
      baitRefillsChangePercent: isQuarter ? 2.0 : -4.0,
      uptimeChangePercent: isYear ? -0.1 : 0.3,
      confidenceChangePercent: isWeek ? 0.5 : 2.0,
    );

    // Trend points
    final trend = <ReportTrendPoint>[];
    final now = DateTime.now();
    int points = isWeek ? 7 : (isYear ? 12 : 30);
    for (int i = 0; i < points; i++) {
      final date = isYear
          ? DateTime(now.year, now.month - points + i + 1, 1)
          : now.subtract(Duration(days: points - i - 1));

      final val = isYear
          ? (baseDetections / 12) * (0.5 + (i % 5) * 0.2)
          : (baseDetections / points) * (0.5 + (i % 7) * 0.2);

      trend.add(ReportTrendPoint(date: date, value: val));
    }

    // Station ledger
    final stations = _dataSource.stations
        .where((s) => s.siteId == siteId)
        .toList();
    final ledger = <StationReportLedgerEntry>[];

    if (stations.isEmpty) {
      // Fallback for isolated tests if no stations exist
      ledger.addAll([
        const StationReportLedgerEntry(
          stationId: 'st_1',
          stationCode: 'RB-07',
          location: 'Warehouse B',
          detections: 22,
          baitRefills: 4,
          uptimePercent: 100,
        ),
        const StationReportLedgerEntry(
          stationId: 'st_2',
          stationCode: 'RB-03',
          location: 'Cold storage',
          detections: 28,
          baitRefills: 6,
          uptimePercent: 100,
        ),
        const StationReportLedgerEntry(
          stationId: 'st_3',
          stationCode: 'RB-01',
          location: 'Kitchen area',
          detections: 18,
          baitRefills: 3,
          uptimePercent: 100,
        ),
        const StationReportLedgerEntry(
          stationId: 'st_4',
          stationCode: 'RB-09',
          location: 'Parking lot',
          detections: 5,
          baitRefills: 1,
          uptimePercent: 87,
        ),
        const StationReportLedgerEntry(
          stationId: 'st_5',
          stationCode: 'RB-12',
          location: 'Main entrance',
          detections: 14,
          baitRefills: 2,
          uptimePercent: 98,
        ),
      ]);
    } else {
      for (int i = 0; i < stations.length; i++) {
        final st = stations[i];
        final dets = (baseDetections * 0.2 * ((i % 3) + 1)).round();
        final refs = (baseRefills * 0.2 * ((i % 3) + 1)).round();
        final up = i % 4 == 0 ? 87.0 : (i % 5 == 0 ? 98.0 : 100.0);
        ledger.add(
          StationReportLedgerEntry(
            stationId: st.id,
            stationCode: st.name,
            location: st.locationDescription,
            detections: dets,
            baitRefills: refs,
            uptimePercent: up,
          ),
        );
      }
      ledger.sort((a, b) => b.detections.compareTo(a.detections));
    }

    final recentExports = _dataSource.reportExports
        .where((e) => e.siteId == siteId)
        .toList();
    recentExports.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

    return ReportsDashboardData(
      summary: summary,
      detectionTrend: trend,
      stationLedger: ledger,
      recentExports: recentExports,
    );
  }

  @override
  Future<ReportExport> generateReport(ReportGenerationRequest request) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate generation

    final now = DateTime.now();
    final format = request.templateType == ReportTemplateType.baitConsumption
        ? ReportFileFormat.csv
        : ReportFileFormat.pdf;

    String prefix;
    switch (request.templateType) {
      case ReportTemplateType.monthlyActivity:
        prefix = 'Monthly_Activity';
        break;
      case ReportTemplateType.baitConsumption:
        prefix = 'Bait_Consumption';
        break;
      case ReportTemplateType.complianceAudit:
        prefix = 'Compliance_Audit';
        break;
    }

    String suffix = '${now.month}${now.year}';
    final fileName = '${prefix}_$suffix.${format.name}';

    final export = ReportExport(
      id: 'export_${now.millisecondsSinceEpoch}',
      siteId: request.siteId,
      templateType: request.templateType,
      format: format,
      title: '$prefix Report',
      fileName: fileName,
      fileSizeBytes: format == ReportFileFormat.csv ? 84000 : 2400000,
      generatedAt: now,
      period: request.period,
    );

    _dataSource.addReportExport(export);

    return export;
  }

  @override
  Future<List<ReportExport>> getRecentExports({required String siteId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final recent = _dataSource.reportExports
        .where((e) => e.siteId == siteId)
        .toList();
    recent.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return recent;
  }

  @override
  bool get supportsExport => true;

  @override
  Stream<ReportsDashboardData> watchDashboardData({
    required String siteId,
    required ReportPeriod period,
  }) async* {
    yield await getDashboardData(siteId: siteId, period: period);
  }
}
