import 'report_type.dart';

class Report {
  final String id;
  final String name;
  final ReportType type;
  final DateTime createdAt;
  final String generatedByUserId;
  final String downloadUrl;

  const Report({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.generatedByUserId,
    required this.downloadUrl,
  });
}
