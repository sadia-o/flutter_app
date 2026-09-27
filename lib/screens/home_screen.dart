import 'package:flutter/material.dart';
import 'alert_detail_screen.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildHealthAndKPIs(),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 16),
              _buildFacilityMap(),
              const SizedBox(height: 16),
              _buildActivityChart(),
              const SizedBox(height: 16),
              _buildSpeciesBreakdown(),
              const SizedBox(height: 16),
              _buildRecentAlerts(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF21D19F),
                  size: 14,
                ),
                const SizedBox(width: 4),
                const Text(
                  'BAITGUARD',
                  style: TextStyle(
                    color: Color(0xFF21D19F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Good morning,',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Jun 17, 2026 · All facilities',
              style: TextStyle(color: Color(0xFF7A8499), fontSize: 13),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const AlertsScreen())),
          child: Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D2E),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: const Color(0xFF252840)),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthAndKPIs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2433)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: 0.87,
                    strokeWidth: 7,
                    backgroundColor: const Color(0xFF1E2433),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF21D19F),
                    ),
                  ),
                ),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '87',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Health',
                      style: TextStyle(color: Color(0xFF7A8499), fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    _kpiCard(
                      'Total',
                      '120',
                      Colors.white,
                      Icons.location_on_outlined,
                    ),
                    const SizedBox(width: 8),
                    _kpiCard(
                      'Active',
                      '118',
                      const Color(0xFF21D19F),
                      Icons.bolt_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _kpiCard(
                      'Refills',
                      '8',
                      const Color(0xFFF59E0B),
                      Icons.water_drop_outlined,
                    ),
                    const SizedBox(width: 8),
                    _kpiCard(
                      'Offline',
                      '2',
                      const Color(0xFFEF4444),
                      Icons.wifi_off_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color valueColor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: valueColor, size: 12),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7A8499),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.refresh_rounded,
        'label': 'Refresh',
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refreshing station data...'),
              backgroundColor: Color(0xFF21D19F),
              duration: Duration(seconds: 2),
            ),
          );
        },
      },
      {
        'icon': Icons.map_outlined,
        'label': 'Map',
        'onTap': () {
          showModalBottomSheet(
            context: context,
            backgroundColor: const Color(0xFF11151F),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => _buildFullMapSheet(),
          );
        },
      },
      {
        'icon': Icons.description_outlined,
        'label': 'Report',
        'onTap': () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF11151F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Generate Report',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Export a PDF report of all station activity?',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF7A8499)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report generated!'),
                        backgroundColor: Color(0xFF21D19F),
                      ),
                    );
                  },
                  child: const Text(
                    'Export PDF',
                    style: TextStyle(color: Color(0xFF21D19F)),
                  ),
                ),
              ],
            ),
          );
        },
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        },
      },
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: a['onTap'] as VoidCallback,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF11151F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2433)),
              ),
              child: Column(
                children: [
                  Icon(
                    a['icon'] as IconData,
                    color: const Color(0xFF21D19F),
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a['label'] as String,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFullMapSheet() {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Live facility map',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '120 stations',
                style: TextStyle(color: Color(0xFF7A8499), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF070A10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2433)),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    bottom: 8,
                    left: 30,
                    child: Text(
                      'ZONE A',
                      style: TextStyle(color: Color(0xFF374151), fontSize: 11),
                    ),
                  ),
                  const Positioned(
                    bottom: 8,
                    left: 140,
                    child: Text(
                      'ZONE B',
                      style: TextStyle(color: Color(0xFF374151), fontSize: 11),
                    ),
                  ),
                  const Positioned(
                    bottom: 8,
                    right: 30,
                    child: Text(
                      'ZONE C',
                      style: TextStyle(color: Color(0xFF374151), fontSize: 11),
                    ),
                  ),
                  _stationPin('01', const Color(0xFF21D19F), 40, 60),
                  _stationPin('07', const Color(0xFFEF4444), 130, 100),
                  _stationPin('03', const Color(0xFFF59E0B), 220, 50),
                  _stationPin('05', const Color(0xFF21D19F), 70, 160),
                  _stationPin('08', const Color(0xFF21D19F), 260, 100),
                  _stationPin('12', const Color(0xFFEF4444), 190, 160),
                  _stationPin('09', const Color(0xFF6B7280), 280, 190),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legendItem('Active', const Color(0xFF21D19F)),
                        _legendItem('Alert', const Color(0xFFEF4444)),
                        _legendItem('Low bait', const Color(0xFFF59E0B)),
                        _legendItem('Offline', const Color(0xFF6B7280)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _mapStatChip('Active', '118', const Color(0xFF21D19F)),
              const SizedBox(width: 8),
              _mapStatChip('Alert', '2', const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _mapStatChip('Low bait', '8', const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _mapStatChip('Offline', '2', const Color(0xFF6B7280)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF7A8499), fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityMap() {
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
            'Live facility map',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF070A10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2433)),
            ),
            child: Stack(
              children: [
                const Positioned(
                  bottom: 8,
                  left: 8,
                  child: Text(
                    'ZONE A',
                    style: TextStyle(color: Color(0xFF374151), fontSize: 10),
                  ),
                ),
                const Positioned(
                  bottom: 8,
                  left: 120,
                  child: Text(
                    'ZONE B',
                    style: TextStyle(color: Color(0xFF374151), fontSize: 10),
                  ),
                ),
                const Positioned(
                  bottom: 8,
                  right: 20,
                  child: Text(
                    'ZONE C',
                    style: TextStyle(color: Color(0xFF374151), fontSize: 10),
                  ),
                ),
                _stationPin('01', const Color(0xFF21D19F), 30, 40),
                _stationPin('07', const Color(0xFFEF4444), 100, 70),
                _stationPin('03', const Color(0xFFF59E0B), 190, 30),
                _stationPin('05', const Color(0xFF21D19F), 60, 100),
                _stationPin('08', const Color(0xFF21D19F), 220, 65),
                _stationPin('12', const Color(0xFFEF4444), 160, 95),
                _stationPin('09', const Color(0xFF6B7280), 230, 110),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendItem('Active', const Color(0xFF21D19F)),
                      _legendItem('Alert', const Color(0xFFEF4444)),
                      _legendItem('Low bait', const Color(0xFFF59E0B)),
                      _legendItem('Offline', const Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationPin(String label, Color color, double left, double top) {
    final bool isActive = color == const Color(0xFF21D19F);
    return Positioned(
      left: left,
      top: top,
      child: isActive
          ? _GlowingPin(label: label, color: color)
          : Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
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
              const Text(
                'Activity — last 24 hrs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    '42',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'detections today',
                    style: TextStyle(color: Color(0xFF7A8499), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '↗ +23% vs yesterday',
            style: TextStyle(color: Color(0xFF21D19F), fontSize: 11),
          ),
          const SizedBox(height: 12),
          const _InteractiveChart(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                ['0h', '3h', '6h', '9h', '12h', '15h', '18h', '21h', '24h']
                    .map(
                      (t) => Text(
                        t,
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

  Widget _buildSpeciesBreakdown() {
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
            'Species breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: 0.58,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFF59E0B),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '87',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'total',
                          style: TextStyle(
                            color: Color(0xFF7A8499),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _speciesRow('Rat', '58%', const Color(0xFFEF4444)),
                    const SizedBox(height: 10),
                    _speciesRow('Mouse', '29%', const Color(0xFFF59E0B)),
                    const SizedBox(height: 10),
                    _speciesRow('Other', '13%', const Color(0xFF6B7280)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _speciesRow(String name, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
          ),
        ),
        Text(
          pct,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAlerts(BuildContext context) {
    final alerts = [
      {
        'title': 'Rat detected',
        'sub': 'RB-07 · Warehouse B · 2:13 AM',
        'status': 'Unresolved',
        'color': 0xFFEF4444,
        'dot': 0xFFEF4444,
      },
      {
        'title': 'Low bait (18%)',
        'sub': 'RB-03 · Cold storage · 11:45 AM',
        'status': 'Pending',
        'color': 0xFFF59E0B,
        'dot': 0xFFF59E0B,
      },
      {
        'title': 'Tamper detected',
        'sub': 'RB-12 · Main entrance · Yesterday',
        'status': 'Unresolved',
        'color': 0xFFEF4444,
        'dot': 0xFFEF4444,
      },
      {
        'title': 'Station offline',
        'sub': 'RB-09 · Parking lot · 2 days ago',
        'status': 'Investigating',
        'color': 0xFF6B7280,
        'dot': 0xFF6B7280,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent alerts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AlertsScreen()),
                ),
                child: const Text(
                  'View all →',
                  style: TextStyle(color: Color(0xFF3B9CFF), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.map(
            (a) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlertDetailScreen(
                      title: a['title'] as String,
                      subtitle: a['sub'] as String,
                      status: a['status'] as String,
                      color: Color(a['color'] as int),
                      icon: Icons.warning_amber_rounded,
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
                        color: Color(
                          (a['color'] as int),
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Color(a['color'] as int),
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
                                  color: Color(a['dot'] as int),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Color(
                          (a['color'] as int),
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        a['status'] as String,
                        style: TextStyle(
                          color: Color(a['color'] as int),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
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

// Interactive chart widget
class _InteractiveChart extends StatefulWidget {
  const _InteractiveChart();

  @override
  State<_InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<_InteractiveChart> {
  double? _touchX;
  int? _touchIndex;
  final List<double> _points = [0.1, 0.15, 0.5, 0.8, 0.6, 0.55, 0.65, 0.4, 0.3];
  final List<String> _values = ['1', '2', '6', '10', '8', '7', '8', '5', '4'];
  final List<String> _times = [
    '0h',
    '3h',
    '6h',
    '9h',
    '12h',
    '15h',
    '18h',
    '21h',
    '24h',
  ];

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
              painter: SimpleLinePainter(touchX: _touchX),
              size: const Size(double.infinity, 80),
            ),
            if (_touchIndex != null && _touchX != null)
              Positioned(
                left: _touchX! - 24,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B9CFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_values[_touchIndex!]} detections\n${_times[_touchIndex!]}',
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
      _touchX = dx.clamp(24, width - 24);
      _touchIndex = index;
    });
  }
}

// Line chart painter
class SimpleLinePainter extends CustomPainter {
  final double? touchX;
  const SimpleLinePainter({this.touchX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B9CFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = [0.1, 0.15, 0.5, 0.8, 0.6, 0.55, 0.65, 0.4, 0.3];
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
          const Color(0xFF3B9CFF).withValues(alpha: 0.2),
          const Color(0xFF3B9CFF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    if (touchX != null) {
      final linePaint = Paint()
        ..color = const Color(0xFF3B9CFF).withValues(alpha: 0.6)
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
      final dotPaint = Paint()..color = const Color(0xFF3B9CFF);
      canvas.drawCircle(Offset(touchX!, dotY), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SimpleLinePainter old) => old.touchX != touchX;
}

// Glowing pin widget
class _GlowingPin extends StatefulWidget {
  final String label;
  final Color color;
  const _GlowingPin({required this.label, required this.color});

  @override
  State<_GlowingPin> createState() => _GlowingPinState();
}

class _GlowingPinState extends State<_GlowingPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: _animation.value * 0.25),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: _animation.value * 0.4),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: _animation.value * 0.8,
                    ),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
