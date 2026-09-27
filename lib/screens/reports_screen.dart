import 'package:flutter/material.dart';
import 'station_detail_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildKPIGrid(),
              const SizedBox(height: 16),
              _buildReportCards(context),
              const SizedBox(height: 16),
              _buildDetectionsChart(),
              const SizedBox(height: 16),
              _buildStationTable(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Reports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Exportable for audits & compliance',
          style: TextStyle(color: Color(0xFF7A8499), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildKPIGrid() {
    final kpis = [
      {
        'value': '87',
        'label': 'Total detections',
        'delta': '+12% vs last month',
        'deltaUp': true,
        'color': 0xFFEF4444,
      },
      {
        'value': '34',
        'label': 'Bait refills done',
        'delta': '-4% vs last month',
        'deltaUp': false,
        'color': 0xFFF59E0B,
      },
      {
        'value': '99.1%',
        'label': 'System uptime',
        'delta': '+0.3% vs last month',
        'deltaUp': true,
        'color': 0xFF21D19F,
      },
      {
        'value': '96%',
        'label': 'Avg AI confidence',
        'delta': '+2% vs last month',
        'deltaUp': true,
        'color': 0xFF3B9CFF,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: kpis.map((k) {
        final up = k['deltaUp'] as bool;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF11151F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E2433)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                k['value'] as String,
                style: TextStyle(
                  color: Color(k['color'] as int),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k['label'] as String,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        up
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 11,
                        color: up
                            ? const Color(0xFF21D19F)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        k['delta'] as String,
                        style: TextStyle(
                          color: up
                              ? const Color(0xFF21D19F)
                              : const Color(0xFFEF4444),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showDownloadDialog(BuildContext context, String title, String format) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF11151F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Download $format?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Export "$title" as a $format file?',
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF7A8499)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title exported as $format!'),
                  backgroundColor: const Color(0xFF21D19F),
                ),
              );
            },
            child: Text(
              'Download $format',
              style: const TextStyle(color: Color(0xFF21D19F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCards(BuildContext context) {
    final reports = [
      {
        'title': 'Monthly activity',
        'sub': 'June 2026 · All stations',
        'btnLabel': 'PDF',
        'btnColor': 0xFF3B9CFF,
        'iconBg': 0xFF1A2D4A,
        'icon': Icons.description_outlined,
        'iconColor': 0xFF3B9CFF,
      },
      {
        'title': 'Bait consumption',
        'sub': 'Last 30 days · CSV',
        'btnLabel': 'CSV',
        'btnColor': 0xFF21D19F,
        'iconBg': 0xFF0E2820,
        'icon': Icons.trending_up_rounded,
        'iconColor': 0xFF21D19F,
      },
      {
        'title': 'Compliance audit',
        'sub': 'Q2 2026 · Full audit trail',
        'btnLabel': 'PDF',
        'btnColor': 0xFFA855F7,
        'iconBg': 0xFF2A1A4A,
        'icon': Icons.shield_outlined,
        'iconColor': 0xFFA855F7,
      },
    ];

    return Column(
      children: reports
          .map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF11151F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E2433)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Color(r['iconBg'] as int),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      r['icon'] as IconData,
                      color: Color(r['iconColor'] as int),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          r['sub'] as String,
                          style: const TextStyle(
                            color: Color(0xFF7A8499),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showDownloadDialog(
                      context,
                      r['title'] as String,
                      r['btnLabel'] as String,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Color(
                          r['btnColor'] as int,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(
                            r['btnColor'] as int,
                          ).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.download_rounded,
                            color: Color(r['btnColor'] as int),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            r['btnLabel'] as String,
                            style: TextStyle(
                              color: Color(r['btnColor'] as int),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDetectionsChart() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2433)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detections — this month',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: CustomPaint(
              painter: _PurpleLinePainter(),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (d) => Text(
                    d,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 9,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStationTable(BuildContext context) {
    final rows = [
      {
        'id': 'RB-07',
        'loc': 'Warehouse B',
        'det': 22,
        'ref': 4,
        'up': '100%',
        'upColor': 0xFF21D19F,
      },
      {
        'id': 'RB-03',
        'loc': 'Cold storage',
        'det': 28,
        'ref': 6,
        'up': '100%',
        'upColor': 0xFF21D19F,
      },
      {
        'id': 'RB-01',
        'loc': 'Kitchen area',
        'det': 18,
        'ref': 3,
        'up': '100%',
        'upColor': 0xFF21D19F,
      },
      {
        'id': 'RB-09',
        'loc': 'Parking lot',
        'det': 5,
        'ref': 1,
        'up': '87%',
        'upColor': 0xFFF59E0B,
      },
      {
        'id': 'RB-12',
        'loc': 'Main entrance',
        'det': 14,
        'ref': 2,
        'up': '98%',
        'upColor': 0xFF3B9CFF,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2433)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Station-by-station — June 2026',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // Table header
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'ID',
                    style: TextStyle(color: Color(0xFF7A8499), fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Location',
                    style: TextStyle(color: Color(0xFF7A8499), fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Det.',
                    style: TextStyle(color: Color(0xFF7A8499), fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Refills',
                    style: TextStyle(color: Color(0xFF7A8499), fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Uptime',
                    style: TextStyle(color: Color(0xFF7A8499), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 0.5, color: const Color(0xFF1E2433)),
          const SizedBox(height: 8),

          // Table rows
          ...rows.map(
            (r) => GestureDetector(
              onTap: () {
                final upText = r['up'] as String;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StationDetailScreen(
                      stationId: r['id'] as String,
                      location: r['loc'] as String,
                      status: upText == '100%' ? 'Online' : 'Warning',
                      bait: '55% bait',
                      battery: '${upText.replaceAll('%', '')}% batt',
                      statusColor: upText == '100%'
                          ? const Color(0xFF21D19F)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        r['id'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        r['loc'] as String,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${r['det']}',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${r['ref']}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Color(r['upColor'] as int),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r['up'] as String,
                            style: TextStyle(
                              color: Color(r['upColor'] as int),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurpleLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA855F7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = [0.45, 0.5, 0.7, 0.6, 0.75, 0.65, 0.6];
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (points[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFA855F7).withValues(alpha: 0.25),
          const Color(0xFFA855F7).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
