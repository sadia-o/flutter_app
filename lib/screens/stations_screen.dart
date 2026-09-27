import 'package:flutter/material.dart';
import 'station_detail_screen.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  String _searchQuery = '';

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
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildStatChips(),
              const SizedBox(height: 16),
              _buildFeaturedStation(),
              const SizedBox(height: 16),
              _buildAllStations(context),
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
              'Stations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '120 total · 118 active',
              style: TextStyle(color: Color(0xFF7A8499), fontSize: 13),
            ),
          ],
        ),
        GestureDetector(
          onTap: _showStationActions,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D2E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF252840)),
            ),
            child: const Icon(
              Icons.more_horiz,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2433)),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Search stations...',
          hintStyle: TextStyle(color: Color(0xFF4B5563)),
          icon: Icon(Icons.search, color: Color(0xFF7A8499), size: 18),
        ),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      ),
    );
  }

  Widget _buildStatChips() {
    final stats = [
      {'value': '98%', 'label': 'Uptime', 'color': 0xFF21D19F},
      {'value': '8', 'label': 'Refills', 'color': 0xFFF59E0B},
      {'value': '42', 'label': 'Detects', 'color': 0xFF3B9CFF},
      {'value': '2', 'label': 'Offline', 'color': 0xFFEF4444},
    ];
    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF11151F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2433)),
            ),
            child: Column(
              children: [
                Text(
                  s['value'] as String,
                  style: TextStyle(
                    color: Color(s['color'] as int),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s['label'] as String,
                  style: const TextStyle(
                    color: Color(0xFF7A8499),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturedStation() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StationDetailScreen(
              stationId: 'RB-07',
              location: 'Warehouse B',
              status: 'Alert',
              bait: '18% bait',
              battery: '82% batt',
              statusColor: Color(0xFFEF4444),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF11151F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E2433)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text(
                      'RB-07',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Warehouse B',
                      style: TextStyle(color: Color(0xFF7A8499), fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Alert',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Camera feed
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF050709),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E2433)),
              ),
              child: Stack(
                children: [
                  // Scanline effect
                  ...List.generate(
                    7,
                    (i) => Positioned(
                      top: i * 20.0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 0.5,
                        color: const Color(0xFF21D19F).withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Camera icon
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_outlined,
                          color: Color(0xFF374151),
                          size: 32,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Night vision feed',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Live badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF21D19F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
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
                  // Bottom info
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: const Text(
                      'Night vision · 24°C',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
            ),
            const SizedBox(height: 12),

            // Bait / Battery / Detections
            Row(
              children: [
                _metricCard(
                  '18%',
                  'Bait',
                  const Color(0xFFF59E0B),
                  Icons.water_drop_outlined,
                  0.18,
                ),
                const SizedBox(width: 8),
                _metricCard(
                  '82%',
                  'Battery',
                  const Color(0xFF21D19F),
                  Icons.bolt,
                  0.82,
                ),
                const SizedBox(width: 8),
                _metricCard(
                  '22',
                  'Detections',
                  const Color(0xFF3B9CFF),
                  Icons.warning_amber_rounded,
                  null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Env row
            Row(
              children: const [
                Icon(Icons.thermostat, color: Color(0xFFF59E0B), size: 14),
                SizedBox(width: 4),
                Text(
                  '24°C',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
                SizedBox(width: 14),
                Icon(Icons.water, color: Color(0xFF3B9CFF), size: 14),
                SizedBox(width: 4),
                Text(
                  '61% hum.',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
                SizedBox(width: 14),
                Icon(Icons.access_time, color: Color(0xFF9CA3AF), size: 14),
                SizedBox(width: 4),
                Text(
                  'Last: 2:13 AM',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStationActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF11151F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Station actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF21D19F),
                ),
                title: const Text(
                  'Refresh station list',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Station list refreshed'),
                      backgroundColor: Color(0xFF21D19F),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.download_rounded,
                  color: Color(0xFF3B9CFF),
                ),
                title: const Text(
                  'Export station snapshot',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Station snapshot exported'),
                      backgroundColor: Color(0xFF3B9CFF),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF7A8499), fontSize: 11),
            ),
            if (progress != null) ...[
              const SizedBox(height: 6),
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

  Widget _buildAllStations(BuildContext context) {
    final stations = [
      {
        'id': 'RB-07',
        'loc': 'Warehouse B',
        'bait': '18% bait',
        'batt': '82% batt',
        'status': 'Alert',
        'dotColor': 0xFFEF4444,
        'statusColor': 0xFFEF4444,
      },
      {
        'id': 'RB-03',
        'loc': 'Cold storage',
        'bait': '22% bait',
        'batt': '91% batt',
        'status': 'Low bait',
        'dotColor': 0xFFF59E0B,
        'statusColor': 0xFFF59E0B,
      },
      {
        'id': 'RB-01',
        'loc': 'Kitchen area',
        'bait': '75% bait',
        'batt': '88% batt',
        'status': 'Online',
        'dotColor': 0xFF21D19F,
        'statusColor': 0xFF21D19F,
      },
      {
        'id': 'RB-05',
        'loc': 'Loading bay',
        'bait': '60% bait',
        'batt': '77% batt',
        'status': 'Online',
        'dotColor': 0xFF21D19F,
        'statusColor': 0xFF21D19F,
      },
      {
        'id': 'RB-09',
        'loc': 'Parking lot',
        'bait': '45% bait',
        'batt': '12% batt',
        'status': 'Offline',
        'dotColor': 0xFF6B7280,
        'statusColor': 0xFF6B7280,
      },
      {
        'id': 'RB-12',
        'loc': 'Main entrance',
        'bait': '33% bait',
        'batt': '65% batt',
        'status': 'Alert',
        'dotColor': 0xFFEF4444,
        'statusColor': 0xFFEF4444,
      },
      {
        'id': 'RB-08',
        'loc': 'East corridor',
        'bait': '80% bait',
        'batt': '90% batt',
        'status': 'Online',
        'dotColor': 0xFF21D19F,
        'statusColor': 0xFF21D19F,
      },
    ];
    final filtered = _searchQuery.isEmpty
        ? stations
        : stations
              .where(
                (s) =>
                    (s['id'] as String).toLowerCase().contains(_searchQuery) ||
                    (s['loc'] as String).toLowerCase().contains(_searchQuery),
              )
              .toList();
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
                'All stations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF11151F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Export CSV?',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Export all station data as a CSV file?',
                        style: TextStyle(color: Color(0xFF9CA3AF)),
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
                                content: Text('Station data exported as CSV!'),
                                backgroundColor: Color(0xFF21D19F),
                              ),
                            );
                          },
                          child: const Text(
                            'Export',
                            style: TextStyle(color: Color(0xFF21D19F)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Export CSV →',
                  style: TextStyle(color: Color(0xFF3B9CFF), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...filtered.map(
            (s) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StationDetailScreen(
                      stationId: s['id'] as String,
                      location: s['loc'] as String,
                      status: s['status'] as String,
                      bait: s['bait'] as String,
                      battery: s['batt'] as String,
                      statusColor: Color(s['statusColor'] as int),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(s['dotColor'] as int),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['id'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            s['loc'] as String,
                            style: const TextStyle(
                              color: Color(0xFF7A8499),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          s['bait'] as String,
                          style: TextStyle(
                            color: Color(s['dotColor'] as int),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          s['batt'] as String,
                          style: const TextStyle(
                            color: Color(0xFF7A8499),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Color(
                          s['statusColor'] as int,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s['status'] as String,
                        style: TextStyle(
                          color: Color(s['statusColor'] as int),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
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
}
