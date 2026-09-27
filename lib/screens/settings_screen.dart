import 'package:flutter/material.dart';
import 'admin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = true;
  bool rodentAlerts = true;
  bool lowBaitAlerts = true;
  bool tamperAlerts = true;
  bool offlineAlerts = false;
  bool darkMode = true;
  bool autoRefresh = true;
  String refreshInterval = '30 seconds';
  String selectedSite = 'All facilities';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11151F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Account'),
            _buildAccountCard(),
            const SizedBox(height: 10),
            _buildAdminAccessButton(),
            const SizedBox(height: 20),

            _sectionTitle('Notifications'),
            _buildCard(
              children: [
                _toggleRow(
                  'Push notifications',
                  'Receive alerts on this device',
                  Icons.notifications_outlined,
                  const Color(0xFF21D19F),
                  pushNotifications,
                  (v) => setState(() => pushNotifications = v),
                ),
                _divider(),
                _toggleRow(
                  'Rodent detected',
                  'Alert when rodent is identified',
                  Icons.warning_amber_rounded,
                  const Color(0xFFEF4444),
                  rodentAlerts,
                  (v) => setState(() => rodentAlerts = v),
                ),
                _divider(),
                _toggleRow(
                  'Low bait warning',
                  'Alert when bait drops below 25%',
                  Icons.water_drop_outlined,
                  const Color(0xFFF59E0B),
                  lowBaitAlerts,
                  (v) => setState(() => lowBaitAlerts = v),
                ),
                _divider(),
                _toggleRow(
                  'Tamper detected',
                  'Alert when station is tampered',
                  Icons.shield_outlined,
                  const Color(0xFFA855F7),
                  tamperAlerts,
                  (v) => setState(() => tamperAlerts = v),
                ),
                _divider(),
                _toggleRow(
                  'Station offline',
                  'Alert when station loses connection',
                  Icons.wifi_off_rounded,
                  const Color(0xFF6B7280),
                  offlineAlerts,
                  (v) => setState(() => offlineAlerts = v),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _sectionTitle('Display'),
            _buildCard(
              children: [
                _toggleRow(
                  'Dark mode',
                  'Use dark theme throughout the app',
                  Icons.dark_mode_outlined,
                  const Color(0xFF21D19F),
                  darkMode,
                  (v) => setState(() => darkMode = v),
                ),
                _divider(),
                _toggleRow(
                  'Auto refresh',
                  'Automatically refresh station data',
                  Icons.refresh_rounded,
                  const Color(0xFF3B9CFF),
                  autoRefresh,
                  (v) => setState(() => autoRefresh = v),
                ),
                _divider(),
                _dropdownRow(
                  'Refresh interval',
                  Icons.timer_outlined,
                  const Color(0xFF3B9CFF),
                  refreshInterval,
                  ['15 seconds', '30 seconds', '1 minute', '5 minutes'],
                  (v) => setState(() => refreshInterval = v!),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _sectionTitle('Site'),
            _buildCard(
              children: [
                _dropdownRow(
                  'Active site',
                  Icons.location_on_outlined,
                  const Color(0xFF21D19F),
                  selectedSite,
                  [
                    'All facilities',
                    'Site A — Bahria Complex',
                    'Site B — Warehouse',
                    'Site C — Hospital',
                  ],
                  (v) => setState(() => selectedSite = v!),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _sectionTitle('System'),
            _buildCard(
              children: [
                _infoRow(
                  'App version',
                  'BaitGuard v1.0.0',
                  Icons.info_outline,
                  const Color(0xFF7A8499),
                ),
                _divider(),
                _infoRow(
                  'Device',
                  'Infinix X663',
                  Icons.phone_android,
                  const Color(0xFF7A8499),
                ),
                _divider(),
                _infoRow(
                  'Last sync',
                  'Just now',
                  Icons.sync,
                  const Color(0xFF21D19F),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sign out button
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
                      'Sign out?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to sign out of BaitGuard?',
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
                              content: Text('Signed out successfully'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign out',
                          style: TextStyle(color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Sign out',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF7A8499),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF11151F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _EditProfileSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF11151F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2433)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF21D19F), Color(0xFF0EA37A)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'SJ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sadia Javed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Administrator · Bahria University',
                    style: TextStyle(color: Color(0xFF7A8499), fontSize: 12),
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

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2433)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildAdminAccessButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF11151F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2433)),
        ),
        child: Row(
          children: const [
            Icon(
              Icons.admin_panel_settings_outlined,
              color: Color(0xFFA855F7),
              size: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Open Admin Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFF7A8499), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7A8499),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF21D19F),
            inactiveThumbColor: const Color(0xFF4B5563),
            inactiveTrackColor: const Color(0xFF1E2433),
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow(
    String title,
    IconData icon,
    Color iconColor,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF1A1D2E),
            style: const TextStyle(color: Color(0xFF21D19F), fontSize: 12),
            underline: const SizedBox(),
            icon: const Icon(
              Icons.chevron_right,
              color: Color(0xFF7A8499),
              size: 18,
            ),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF7A8499), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 0.5, color: const Color(0xFF1E2433));
}

class _EditProfileSheet extends StatefulWidget {
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _nameController = TextEditingController(text: 'Sadia Javed');
  final _emailController = TextEditingController(text: 'sadia@bahria.edu.pk');
  final _roleController = TextEditingController(text: 'Administrator');
  final _enrollController = TextEditingController(text: '09-136242-044');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _enrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Color(0xFF7A8499)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF21D19F), Color(0xFF0EA37A)],
                    ),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: const Center(
                    child: Text(
                      'SJ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF21D19F),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _editField('Full name', _nameController, Icons.person_outlined),
          const SizedBox(height: 12),
          _editField('Email', _emailController, Icons.email_outlined),
          const SizedBox(height: 12),
          _editField('Role', _roleController, Icons.badge_outlined),
          const SizedBox(height: 12),
          _editField(
            'Enrollment No.',
            _enrollController,
            Icons.numbers_outlined,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully!'),
                  backgroundColor: Color(0xFF21D19F),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF21D19F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Save changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2433)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF7A8499), fontSize: 12),
          prefixIcon: Icon(icon, color: const Color(0xFF21D19F), size: 18),
        ),
      ),
    );
  }
}
