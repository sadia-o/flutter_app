enum ReportPeriodType { week, month, quarter, year }

class ReportPeriod {
  final ReportPeriodType type;
  final DateTime anchorDate;

  const ReportPeriod({required this.type, required this.anchorDate});
}

class ReportSummary {
  final int totalDetections;
  final int? baitRefills;
  final double? systemUptimePercent;
  final double? averageAiConfidencePercent;
  final double? detectionsChangePercent;
  final double? baitRefillsChangePercent;
  final double? uptimeChangePercent;
  final double? confidenceChangePercent;

  const ReportSummary({
    required this.totalDetections,
    this.baitRefills,
    this.systemUptimePercent,
    this.averageAiConfidencePercent,
    this.detectionsChangePercent,
    this.baitRefillsChangePercent,
    this.uptimeChangePercent,
    this.confidenceChangePercent,
  });
}

class ReportTrendPoint {
  final DateTime date;
  final double value;

  const ReportTrendPoint({required this.date, required this.value});
}

class StationReportLedgerEntry {
  final String stationId;
  final String stationCode;
  final String location;
  final int detections;
  final int? baitRefills;
  final double? uptimePercent;

  const StationReportLedgerEntry({
    required this.stationId,
    required this.stationCode,
    required this.location,
    required this.detections,
    this.baitRefills,
    this.uptimePercent,
  });
}

enum ReportFileFormat { pdf, csv }

enum ReportTemplateType { monthlyActivity, baitConsumption, complianceAudit }

class ReportTemplate {
  final ReportTemplateType type;
  final String title;
  final String subtitle;
  final ReportFileFormat format;

  const ReportTemplate({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.format,
  });
}

class ReportExport {
  final String id;
  final String siteId;
  final ReportTemplateType templateType;
  final ReportFileFormat format;
  final String title;
  final String fileName;
  final int fileSizeBytes;
  final DateTime generatedAt;
  final ReportPeriod period;

  const ReportExport({
    required this.id,
    required this.siteId,
    required this.templateType,
    required this.format,
    required this.title,
    required this.fileName,
    required this.fileSizeBytes,
    required this.generatedAt,
    required this.period,
  });
}

class ReportGenerationRequest {
  final String siteId;
  final String generatedByUserId;
  final ReportTemplateType templateType;
  final ReportPeriod period;

  const ReportGenerationRequest({
    required this.siteId,
    required this.generatedByUserId,
    required this.templateType,
    required this.period,
  });
}

class ReportsDashboardData {
  final ReportSummary summary;
  final List<ReportTrendPoint> detectionTrend;
  final List<StationReportLedgerEntry> stationLedger;
  final List<ReportExport> recentExports;

  const ReportsDashboardData({
    required this.summary,
    required this.detectionTrend,
    required this.stationLedger,
    required this.recentExports,
  });
}
