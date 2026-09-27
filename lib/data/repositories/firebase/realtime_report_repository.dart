import 'dart:async';
import '../../../domain/models/report_models.dart';
import '../../../domain/repositories/report_repository.dart';
import 'realtime_station_data_source.dart';

class RealtimeReportRepository implements ReportRepository {
  final RealtimeStationDataSource _dataSource;

  RealtimeReportRepository(this._dataSource);

  @override
  bool get supportsExport => false;

  @override
  Future<ReportsDashboardData> getDashboardData({
    required String siteId,
    required ReportPeriod period,
  }) async {
    if (siteId != RealtimeStationDataSource.kPilotFacilityId) {
      return _buildEmptyReportsData();
    }

    final station = await _dataSource.fetchStation(
      RealtimeStationDataSource.kPilotStationId,
    );
    final allEvents = await _dataSource.fetchStationEvents(
      RealtimeStationDataSource.kPilotStationId,
    );

    final (startDate, endDate) = _resolveDateRange(period);

    // Inclusive start, exclusive end
    final periodEvents = allEvents.where((e) {
      final ts = e.timestamp.toLocal();
      return !ts.isBefore(startDate) && ts.isBefore(endDate);
    }).toList();

    final totalDetections = periodEvents.length;

    final summary = ReportSummary(
      totalDetections: totalDetections,
      baitRefills: null, // Unsupported by RTDB schema
      systemUptimePercent: null, // Unsupported by RTDB schema
      averageAiConfidencePercent: null, // Unsupported by RTDB schema
      detectionsChangePercent: null,
      baitRefillsChangePercent: null,
      uptimeChangePercent: null,
      confidenceChangePercent: null,
    );

    final trendPoints = _computeTrendPoints(
      periodEvents,
      startDate,
      endDate,
      period.type,
    );

    final ledger = <StationReportLedgerEntry>[];
    if (station != null) {
      ledger.add(
        StationReportLedgerEntry(
          stationId: station.id,
          stationCode: station.name,
          location: station.locationDescription,
          detections: totalDetections,
          baitRefills: null,
          uptimePercent: null,
        ),
      );
    }

    return ReportsDashboardData(
      summary: summary,
      detectionTrend: trendPoints,
      stationLedger: ledger,
      recentExports: const [],
    );
  }

  @override
  Stream<ReportsDashboardData> watchDashboardData({
    required String siteId,
    required ReportPeriod period,
  }) async* {
    yield await getDashboardData(siteId: siteId, period: period);

    await for (final _ in _dataSource.eventsStream) {
      yield await getDashboardData(siteId: siteId, period: period);
    }
  }

  @override
  Future<ReportExport> generateReport(ReportGenerationRequest request) async {
    throw UnsupportedError(
      'Report file generation and export are unsupported in this read-only pilot.',
    );
  }

  @override
  Future<List<ReportExport>> getRecentExports({required String siteId}) async {
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Strict Calendar Date Range and Trend Computation
  // ---------------------------------------------------------------------------

  (DateTime, DateTime) _resolveDateRange(ReportPeriod period) {
    final anchor = period.anchorDate;
    switch (period.type) {
      case ReportPeriodType.week:
        // Consistent 7-day period ending at the end of anchorDate's day (inclusive 7 days)
        final start = DateTime(anchor.year, anchor.month, anchor.day - 6);
        final end = DateTime(anchor.year, anchor.month, anchor.day + 1);
        return (start, end);

      case ReportPeriodType.month:
        // Calendar month: 1st of month to 1st of next month
        final start = DateTime(anchor.year, anchor.month, 1);
        final end = DateTime(anchor.year, anchor.month + 1, 1);
        return (start, end);

      case ReportPeriodType.quarter:
        // Calendar quarter: 3 calendar months
        final qStartMonth = ((anchor.month - 1) ~/ 3) * 3 + 1;
        final start = DateTime(anchor.year, qStartMonth, 1);
        final end = DateTime(anchor.year, qStartMonth + 3, 1);
        return (start, end);

      case ReportPeriodType.year:
        // Calendar year: Jan 1 to Jan 1 of next year
        final start = DateTime(anchor.year, 1, 1);
        final end = DateTime(anchor.year + 1, 1, 1);
        return (start, end);
    }
  }

  List<ReportTrendPoint> _computeTrendPoints(
    List<dynamic> events,
    DateTime startDate,
    DateTime endDate,
    ReportPeriodType type,
  ) {
    final points = <ReportTrendPoint>[];

    if (type == ReportPeriodType.week) {
      // Exactly 7 daily buckets
      for (int i = 0; i < 7; i++) {
        final bucketStart = startDate.add(Duration(days: i));
        final bucketEnd = bucketStart.add(const Duration(days: 1));

        final count = events.where((e) {
          final ts = (e.timestamp as DateTime).toLocal();
          return !ts.isBefore(bucketStart) && ts.isBefore(bucketEnd);
        }).length;

        points.add(
          ReportTrendPoint(date: bucketStart, value: count.toDouble()),
        );
      }
      return points;
    }

    if (type == ReportPeriodType.year) {
      // Exactly 12 monthly buckets
      for (int m = 1; m <= 12; m++) {
        final bucketStart = DateTime(startDate.year, m, 1);
        final bucketEnd = DateTime(startDate.year, m + 1, 1);

        final count = events.where((e) {
          final ts = (e.timestamp as DateTime).toLocal();
          return !ts.isBefore(bucketStart) && ts.isBefore(bucketEnd);
        }).length;

        points.add(
          ReportTrendPoint(date: bucketStart, value: count.toDouble()),
        );
      }
      return points;
    }

    // Month & Quarter: step by 3 or 7 days, ensuring contiguous, non-overlapping intervals
    final totalDays = endDate.difference(startDate).inDays;
    final stepDays = (totalDays / 7).clamp(1, 30).round();

    DateTime current = startDate;
    while (current.isBefore(endDate)) {
      var next = current.add(Duration(days: stepDays));
      if (next.isAfter(endDate)) {
        next = endDate;
      }

      final count = events.where((e) {
        final ts = (e.timestamp as DateTime).toLocal();
        return !ts.isBefore(current) && ts.isBefore(next);
      }).length;

      points.add(ReportTrendPoint(date: current, value: count.toDouble()));
      current = next;
    }

    return points;
  }

  ReportsDashboardData _buildEmptyReportsData() {
    return const ReportsDashboardData(
      summary: ReportSummary(
        totalDetections: 0,
        baitRefills: null,
        systemUptimePercent: null,
        averageAiConfidencePercent: null,
        detectionsChangePercent: null,
        baitRefillsChangePercent: null,
        uptimeChangePercent: null,
        confidenceChangePercent: null,
      ),
      detectionTrend: [],
      stationLedger: [],
      recentExports: [],
    );
  }
}
