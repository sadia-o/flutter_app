import 'package:flutter/material.dart';
import 'alert_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedFilter = 0;
  final filters = ['All', 'Rodent', 'Low bait', 'Tamper', 'Offline'];

  final alerts = [
    {
      'title': 'Rat detected',
      'sub': 'RB-07 · Warehouse B · 2:13 AM',
      'status': 'Unresolved',
      'dotColor': 0xFFEF4444,
      'statusColor': 0xFFEF4444,
      'icon': Icons.warning_amber_rounded,
    },
    {
      'title': 'Low bait (18%)',
      'sub': 'RB-03 · Cold storage · 11:45 AM',
      'status': 'Pending',
      'dotColor': 0xFFF59E0B,
      'statusColor': 0xFFF59E0B,
      'icon': Icons.water_drop_outlined,
    },
    {
      'title': 'Tamper detected',
      'sub': 'RB-12 · Main entrance · Yesterday',
      'status': 'Unresolved',
      'dotColor': 0xFFEF4444,
      'statusColor': 0xFFEF4444,
      'icon': Icons.shield_outlined,
    },
    {
      'title': 'Station offline',
      'sub': 'RB-09 · Parking lot · 2 days ago',
      'status': 'Investigating',
      'dotColor': 0xFF6B7280,
      'statusColor': 0xFF6B7280,
      'icon': Icons.wifi_off_rounded,
    },
    {
      'title': 'Mouse detected',
      'sub': 'RB-01 · Kitchen area · 3 days ago',
      'status': 'Resolved',
      'dotColor': 0xFF21D19F,
      'statusColor': 0xFF21D19F,
      'icon': Icons.warning_amber_rounded,
    },
    {
      'title': 'Low bait (22%)',
      'sub': 'RB-05 · Loading bay · 4 days ago',
      'status': 'Resolved',
      'dotColor': 0xFF21D19F,
      'statusColor': 0xFF21D19F,
      'icon': Icons.water_drop_outlined,
    },
  ];

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
              _buildPriorityBanner(),
              const SizedBox(height: 16),
              _buildFilterChips(),
              const SizedBox(height: 16),
              _buildAlertsList(),
              const SizedBox(height: 16),
              _buildWeeklyChart(),
              const SizedBox(height: 16),
              _buildWeekByType(),
              const SizedBox(height: 16),
              _buildHotspots(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Alerts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '12 unread · 2 unresolved',
              style: TextStyle(color: Color(0xFF7A8499), fontSize: 13),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            setState(() => _selectedFilter = 0);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Showing active alerts first'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '2 active',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBanner() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF11151F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'High-priority alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _priorityItem('RB-07', 'Warehouse B', 'Rat detected · 2:13 AM'),
                const SizedBox(height: 12),
                _priorityItem(
                  'RB-12',
                  'Main entrance',
                  'Tamper detected · Yesterday',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2 high-priority alerts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'RB-07 Warehouse B & RB-12 Main entrance\nrequire immediate attention',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF7A8499), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _priorityItem(String id, String loc, String desc) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlertDetailScreen(
              title: desc.split('·')[0].trim(),
              subtitle:
                  '$id · $loc · ${desc.split('·').length > 1 ? desc.split('·')[1].trim() : ""}',
              status: 'Unresolved',
              color: const Color(0xFFEF4444),
              icon: Icons.warning_amber_rounded,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$id · $loc',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF7A8499), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.asMap().entries.map((e) {
          final selected = _selectedFilter == e.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = e.key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFF11151F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.white : const Color(0xFF1E2433),
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: selected ? Colors.black : const Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlertsList() {
    // Filter alerts based on selected filter
    final filtered = _selectedFilter == 0
        ? alerts
        : alerts.where((a) {
            final title = (a['title'] as String).toLowerCase();
            switch (_selectedFilter) {
              case 1: // Rodent
                return title.contains('rat') || title.contains('mouse');
              case 2: // Low bait
                return title.contains('bait');
              case 3: // Tamper
                return title.contains('tamper');
              case 4: // Offline
                return title.contains('offline');
              default:
                return true;
            }
          }).toList();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedFilter == 0
                    ? 'All alerts'
                    : '${filters[_selectedFilter]} alerts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${filtered.length} total',
                style: const TextStyle(color: Color(0xFF7A8499), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No alerts in this category',
                  style: TextStyle(color: Color(0xFF7A8499), fontSize: 13),
                ),
              ),
            )
          else
            ...filtered.map(
              (a) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlertDetailScreen(
                        title: a['title'] as String,
                        subtitle: a['sub'] as String,
                        status: a['status'] as String,
                        color: Color(a['dotColor'] as int),
                        icon: a['icon'] as IconData,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(
                            a['dotColor'] as int,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          a['icon'] as IconData,
                          color: Color(a['dotColor'] as int),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Color(a['dotColor'] as int),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  a['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a['sub'] as String,
                              style: const TextStyle(
                                color: Color(0xFF7A8499),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Color(
                            a['statusColor'] as int,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          a['status'] as String,
                          style: TextStyle(
                            color: Color(a['statusColor'] as int),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF7A8499),
                        size: 16,
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

  Widget _buildWeeklyChart() {
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
            'Weekly activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _TouchableRedChart(),
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

  Widget _buildWeekByType() {
    final types = [
      {
        'label': 'Rodent detections',
        'value': 14,
        'max': 14,
        'color': 0xFFEF4444,
      },
      {
        'label': 'Low bait warnings',
        'value': 8,
        'max': 14,
        'color': 0xFFF59E0B,
      },
      {'label': 'Tamper alerts', 'value': 3, 'max': 14, 'color': 0xFFA855F7},
      {'label': 'Offline events', 'value': 2, 'max': 14, 'color': 0xFF6B7280},
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
            'This week by type',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ...types.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t['label'] as String,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${t['value']}',
                        style: TextStyle(
                          color: Color(t['color'] as int),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (t['value'] as int) / (t['max'] as int),
                      backgroundColor: const Color(0xFF1A2030),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(t['color'] as int),
                      ),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspots() {
    final hotspots = [
      {'id': 'RB-03', 'loc': 'Cold storage', 'visits': 28, 'pct': 1.0},
      {'id': 'RB-07', 'loc': 'Warehouse B', 'visits': 22, 'pct': 0.79},
      {'id': 'RB-01', 'loc': 'Kitchen area', 'visits': 18, 'pct': 0.64},
      {'id': 'RB-12', 'loc': 'Main entrance', 'visits': 14, 'pct': 0.50},
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
            'Hotspot stations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...hotspots.map(
            (h) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlertDetailScreen(
                      title: 'Frequent activity hotspot',
                      subtitle:
                          '${h['id']} · ${h['loc']} · ${h['visits']} visits this week',
                      status: 'Investigating',
                      color: const Color(0xFF3B9CFF),
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2D4A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF3B9CFF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h['id'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            h['loc'] as String,
                            style: const TextStyle(
                              color: Color(0xFF7A8499),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: h['pct'] as double,
                          backgroundColor: const Color(0xFF1A2030),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B9CFF),
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${h['visits']} visits',
                      style: const TextStyle(
                        color: Color(0xFF7A8499),
                        fontSize: 11,
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

  // ignore: non_constant_identifier_names
  Widget _TouchableRedChart() {
    return _RedChartInteractive();
  }
}

class _RedLinePainter extends CustomPainter {
  final double? touchX;
  const _RedLinePainter({this.touchX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = [0.4, 0.3, 0.6, 0.5, 0.45, 0.7, 0.55];
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
          const Color(0xFFEF4444).withValues(alpha: 0.2),
          const Color(0xFFEF4444).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    // Touch indicator
    if (touchX != null) {
      final linePaint = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.6)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(touchX!, 0),
        Offset(touchX!, size.height),
        linePaint,
      );
      final ratio = touchX! / size.width;
      final idx = (ratio * (points.length - 1)).round().clamp(
        0,
        points.length - 1,
      );
      final dotY = size.height - (points[idx] * size.height);
      final dotPaint = Paint()..color = const Color(0xFFEF4444);
      canvas.drawCircle(Offset(touchX!, dotY), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RedLinePainter old) => old.touchX != touchX;
}

class _RedChartInteractive extends StatefulWidget {
  @override
  State<_RedChartInteractive> createState() => _RedChartInteractiveState();
}

class _RedChartInteractiveState extends State<_RedChartInteractive> {
  double? _touchX;
  int? _touchIndex;

  final List<double> _points = [0.4, 0.3, 0.6, 0.5, 0.45, 0.7, 0.55];
  final List<String> _values = ['5', '4', '8', '7', '6', '9', '7'];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: GestureDetector(
        onTapDown: (d) => _onTouch(d.localPosition.dx, context),
        onPanUpdate: (d) => _onTouch(d.localPosition.dx, context),
        onPanEnd: (_) => setState(() {
          _touchX = null;
          _touchIndex = null;
        }),
        child: Stack(
          children: [
            CustomPaint(
              painter: _RedLinePainter(touchX: _touchX),
              size: const Size(double.infinity, 80),
            ),
            if (_touchIndex != null && _touchX != null)
              Positioned(
                left: _touchX! - 28,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_values[_touchIndex!]} alerts\n${_days[_touchIndex!]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onTouch(double dx, BuildContext context) {
    final width = context.size?.width ?? 300;
    final index = ((dx / width) * (_points.length - 1)).round().clamp(
      0,
      _points.length - 1,
    );
    setState(() {
      _touchX = dx.clamp(28, width - 28);
      _touchIndex = index;
    });
  }
}
