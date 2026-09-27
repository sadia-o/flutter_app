import 'package:flutter/material.dart';

class StationDetailScreen extends StatefulWidget {
  final String stationId;
  final String location;
  final String status;
  final String bait;
  final String battery;
  final Color statusColor;

  const StationDetailScreen({
    super.key,
    required this.stationId,
    required this.location,
    required this.status,
    required this.bait,
    required this.battery,
    required this.statusColor,
  });

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baitValue =
        double.tryParse(
          widget.bait.replaceAll('%', '').replaceAll(' bait', ''),
        ) ??
        50;
    final battValue =
        double.tryParse(
          widget.battery.replaceAll('%', '').replaceAll(' batt', ''),
        ) ??
        50;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11151F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.stationId,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.location,
              style: const TextStyle(color: Color(0xFF7A8499), fontSize: 12),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                widget.status,
                style: TextStyle(
                  color: widget.statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camera feed
            _buildCameraFeed(),
            const SizedBox(height: 16),

            // Metrics
            Row(
              children: [
                _metricCard(
                  '${baitValue.toInt()}%',
                  'Bait',
                  const Color(0xFFF59E0B),
                  Icons.water_drop_outlined,
                  baitValue / 100,
                ),
                const SizedBox(width: 10),
                _metricCard(
                  '${battValue.toInt()}%',
                  'Battery',
                  const Color(0xFF21D19F),
                  Icons.bolt,
                  battValue / 100,
                ),
                const SizedBox(width: 10),
                _metricCard(
                  '22',
                  'Detections',
                  const Color(0xFF3B9CFF),
                  Icons.warning_amber_rounded,
                  null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Environment
            _buildEnvCard(),
            const SizedBox(height: 16),

            // Detection history
            _buildDetectionHistory(),
            const SizedBox(height: 16),

            // Actions
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraFeed() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF050709),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2433)),
      ),
      child: Stack(
        children: [
          // Scanlines
          ...List.generate(
            10,
            (i) => Positioned(
              top: i * 20.0,
              left: 0,
              right: 0,
              child: Container(
                height: 0.5,
                color: const Color(0xFF21D19F).withValues(alpha: 0.05),
              ),
            ),
          ),
          // Camera icon center
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_outlined,
                  color: Color(0xFF374151),
                  size: 40,
                ),
                SizedBox(height: 8),
                Text(
                  'Night vision feed',
                  style: TextStyle(color: Color(0xFF374151), fontSize: 13),
                ),
              ],
            ),
          ),
          // Live badge
          Positioned(
            top: 12,
            left: 12,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(
                        0xFF21D19F,
                      ).withValues(alpha: _pulseAnimation.value),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Color(0xFF21D19F),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom info
          Positioned(
            bottom: 10,
            left: 12,
            child: const Text(
              'Night vision · 24°C',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Rat · 96% AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    String value,
    String label,
    Color color,
    IconData icon,
    double? progress,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF11151F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2433)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF7A8499), fontSize: 11),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF252840),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2433)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _envItem(
            Icons.thermostat,
            '24°C',
            'Temperature',
            const Color(0xFFF59E0B),
          ),
          _divider(),
          _envItem(Icons.water, '61%', 'Humidity', const Color(0xFF3B9CFF)),
          _divider(),
          _envItem(
            Icons.access_time,
            '2:13 AM',
            'Last seen',
            const Color(0xFF9CA3AF),
          ),
          _divider(),
          _envItem(
            Icons.location_on_outlined,
            'Zone B',
            'Zone',
            const Color(0xFF21D19F),
          ),
        ],
      ),
    );
  }

  Widget _envItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF7A8499), fontSize: 10),
        ),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 0.5, height: 40, color: const Color(0xFF1E2433));

  Widget _buildDetectionHistory() {
    final events = [
      {
        'time': '2:13 AM',
        'type': 'Rat detected',
        'conf': '96%',
        'color': 0xFFEF4444,
      },
      {
        'time': '11:58 PM',
        'type': 'Motion trigger',
        'conf': '—',
        'color': 0xFF7A8499,
      },
      {
        'time': '9:42 PM',
        'type': 'Mouse detected',
        'conf': '89%',
        'color': 0xFFF59E0B,
      },
      {
        'time': '6:17 PM',
        'type': 'Motion trigger',
        'conf': '—',
        'color': 0xFF7A8499,
      },
      {
        'time': '3:05 AM',
        'type': 'Rat detected',
        'conf': '94%',
        'color': 0xFFEF4444,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2433)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detection history',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...events.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(e['color'] as int),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e['type'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    e['conf'] as String,
                    style: TextStyle(
                      color: Color(e['color'] as int),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    e['time'] as String,
                    style: const TextStyle(
                      color: Color(0xFF7A8499),
                      fontSize: 11,
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

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bait refill request sent!'),
                  backgroundColor: Color(0xFFF59E0B),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Refill bait',
                    style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Station report exported!'),
                  backgroundColor: Color(0xFF3B9CFF),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B9CFF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B9CFF).withValues(alpha: 0.4),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: Color(0xFF3B9CFF),
                    size: 22,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Export report',
                    style: TextStyle(color: Color(0xFF3B9CFF), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF11151F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Mark as resolved?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    'Mark all alerts for ${widget.stationId} as resolved?',
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
                          const SnackBar(
                            content: Text('Alerts resolved!'),
                            backgroundColor: Color(0xFF21D19F),
                          ),
                        );
                      },
                      child: const Text(
                        'Resolve',
                        style: TextStyle(color: Color(0xFF21D19F)),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF21D19F).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF21D19F).withValues(alpha: 0.4),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF21D19F),
                    size: 22,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Resolve',
                    style: TextStyle(color: Color(0xFF21D19F), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
