import 'package:flutter/material.dart';

// User model
class AppUser {
  String id;
  String name;
  String email;
  String role;
  String initials;
  bool isActive;
  String joinDate;
  List<String> siteAccess;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
    required this.isActive,
    required this.joinDate,
    required this.siteAccess,
  });
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final List<AppUser> _users = [
    AppUser(
      id: '1',
      name: 'Sadia Javed',
      email: 'sadia@bahria.edu.pk',
      role: 'Admin',
      initials: 'SJ',
      isActive: true,
      joinDate: 'Jan 2026',
      siteAccess: ['All facilities'],
    ),
    AppUser(
      id: '2',
      name: 'Ahmed Khan',
      email: 'ahmed@bahria.edu.pk',
      role: 'Technician',
      initials: 'AK',
      isActive: true,
      joinDate: 'Feb 2026',
      siteAccess: ['Site A', 'Site B'],
    ),
    AppUser(
      id: '3',
      name: 'Sara Malik',
      email: 'sara@bahria.edu.pk',
      role: 'Viewer',
      initials: 'SM',
      isActive: true,
      joinDate: 'Mar 2026',
      siteAccess: ['Site A'],
    ),
    AppUser(
      id: '4',
      name: 'Usman Ali',
      email: 'usman@bahria.edu.pk',
      role: 'Technician',
      initials: 'UA',
      isActive: false,
      joinDate: 'Apr 2026',
      siteAccess: ['Site C'],
    ),
    AppUser(
      id: '5',
      name: 'Ayesha Tariq',
      email: 'ayesha@bahria.edu.pk',
      role: 'Viewer',
      initials: 'AT',
      isActive: true,
      joinDate: 'May 2026',
      siteAccess: ['Site B', 'Site C'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin':
        return const Color(0xFFA855F7);
      case 'Technician':
        return const Color(0xFF3B9CFF);
      case 'Viewer':
        return const Color(0xFF21D19F);
      default:
        return const Color(0xFF7A8499);
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings_outlined;
      case 'Technician':
        return Icons.build_outlined;
      case 'Viewer':
        return Icons.visibility_outlined;
      default:
        return Icons.person_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? _users
        : _users
              .where(
                (u) =>
                    u.name.toLowerCase().contains(_searchQuery) ||
                    u.email.toLowerCase().contains(_searchQuery) ||
                    u.role.toLowerCase().contains(_searchQuery),
              )
              .toList();

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
          'Admin Panel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_outlined,
              color: Color(0xFF21D19F),
            ),
            onPressed: () => _showAddUserSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF21D19F),
          labelColor: const Color(0xFF21D19F),
          unselectedLabelColor: const Color(0xFF7A8499),
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Roles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // USERS TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats row
                Row(
                  children: [
                    _statChip('Total', '${_users.length}', Colors.white),
                    const SizedBox(width: 8),
                    _statChip(
                      'Active',
                      '${_users.where((u) => u.isActive).length}',
                      const Color(0xFF21D19F),
                    ),
                    const SizedBox(width: 8),
                    _statChip(
                      'Inactive',
                      '${_users.where((u) => !u.isActive).length}',
                      const Color(0xFF7A8499),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11151F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E2433)),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search users...',
                      hintStyle: TextStyle(color: Color(0xFF4B5563)),
                      icon: Icon(
                        Icons.search,
                        color: Color(0xFF7A8499),
                        size: 18,
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                  ),
                ),
                const SizedBox(height: 14),

                // Users list
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF11151F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E2433)),
                  ),
                  child: Column(
                    children: filtered.asMap().entries.map((e) {
                      final i = e.key;
                      final u = e.value;
                      return Column(
                        children: [
                          _userRow(context, u),
                          if (i < filtered.length - 1)
                            Container(
                              height: 0.5,
                              color: const Color(0xFF1E2433),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ROLES TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Role definitions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                _roleCard(
                  'Admin',
                  'Full access to all features, users, and settings.',
                  const Color(0xFFA855F7),
                  Icons.admin_panel_settings_outlined,
                  [
                    'Manage all users and roles',
                    'View and edit all stations',
                    'Export all reports',
                    'Configure system settings',
                    'Access admin panel',
                  ],
                  _users.where((u) => u.role == 'Admin').length,
                ),
                const SizedBox(height: 12),
                _roleCard(
                  'Technician',
                  'Can view stations and resolve alerts.',
                  const Color(0xFF3B9CFF),
                  Icons.build_outlined,
                  [
                    'View all assigned stations',
                    'Resolve and dismiss alerts',
                    'Request bait refills',
                    'Export station reports',
                    'Cannot manage users',
                  ],
                  _users.where((u) => u.role == 'Technician').length,
                ),
                const SizedBox(height: 12),
                _roleCard(
                  'Viewer',
                  'Read-only access to dashboards.',
                  const Color(0xFF21D19F),
                  Icons.visibility_outlined,
                  [
                    'View overview dashboard',
                    'View station status',
                    'View alerts (read only)',
                    'Cannot resolve alerts',
                    'Cannot export reports',
                  ],
                  _users.where((u) => u.role == 'Viewer').length,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF21D19F),
        onPressed: () => _showAddUserSheet(context),
        child: const Icon(Icons.person_add_outlined, color: Colors.white),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF11151F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E2433)),
        ),
        child: Column(
          children: [
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
          ],
        ),
      ),
    );
  }

  Widget _userRow(BuildContext context, AppUser u) {
    return GestureDetector(
      onTap: () => _showEditUserSheet(context, u),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _roleColor(u.role),
                    _roleColor(u.role).withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(21),
              ),
              child: Center(
                child: Text(
                  u.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    u.email,
                    style: const TextStyle(
                      color: Color(0xFF7A8499),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor(u.role).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_roleIcon(u.role), color: _roleColor(u.role), size: 11),
                  const SizedBox(width: 3),
                  Text(
                    u.role,
                    style: TextStyle(
                      color: _roleColor(u.role),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Active dot
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: u.isActive
                    ? const Color(0xFF21D19F)
                    : const Color(0xFF6B7280),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFF7A8499), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(
    String role,
    String description,
    Color color,
    IconData icon,
    List<String> permissions,
    int userCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$userCount users',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Permissions',
            style: TextStyle(
              color: Color(0xFF7A8499),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...permissions.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    p.contains('Cannot') ? Icons.close : Icons.check,
                    color: p.contains('Cannot')
                        ? const Color(0xFF6B7280)
                        : color,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    p,
                    style: TextStyle(
                      color: p.contains('Cannot')
                          ? const Color(0xFF6B7280)
                          : const Color(0xFFD1D5DB),
                      fontSize: 12,
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

  // ADD USER SHEET
  void _showAddUserSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = 'Viewer';
    List<String> selectedSites = ['Site A'];
    final sites = ['All facilities', 'Site A', 'Site B', 'Site C'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF11151F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add new user',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Color(0xFF7A8499)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                _sheetField('Full name', nameCtrl, Icons.person_outlined),
                const SizedBox(height: 12),

                // Email
                _sheetField(
                  'Email address',
                  emailCtrl,
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Role selector
                const Text(
                  'Role',
                  style: TextStyle(
                    color: Color(0xFF7A8499),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Admin', 'Technician', 'Viewer']
                      .map(
                        (r) => Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedRole = r),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedRole == r
                                    ? _roleColor(r).withValues(alpha: 0.2)
                                    : const Color(0xFF0B0E14),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedRole == r
                                      ? _roleColor(r)
                                      : const Color(0xFF1E2433),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _roleIcon(r),
                                    color: selectedRole == r
                                        ? _roleColor(r)
                                        : const Color(0xFF7A8499),
                                    size: 18,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    r,
                                    style: TextStyle(
                                      color: selectedRole == r
                                          ? _roleColor(r)
                                          : const Color(0xFF7A8499),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Site access
                const Text(
                  'Site access',
                  style: TextStyle(
                    color: Color(0xFF7A8499),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sites
                      .map(
                        (s) => GestureDetector(
                          onTap: () => setSheetState(() {
                            if (selectedSites.contains(s)) {
                              selectedSites.remove(s);
                            } else {
                              selectedSites.add(s);
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selectedSites.contains(s)
                                  ? const Color(
                                      0xFF21D19F,
                                    ).withValues(alpha: 0.2)
                                  : const Color(0xFF0B0E14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedSites.contains(s)
                                    ? const Color(0xFF21D19F)
                                    : const Color(0xFF1E2433),
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color: selectedSites.contains(s)
                                    ? const Color(0xFF21D19F)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),

                // Add button
                GestureDetector(
                  onTap: () {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }
                    final newUser = AppUser(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text,
                      email: emailCtrl.text,
                      role: selectedRole,
                      initials: nameCtrl.text
                          .split(' ')
                          .map((n) => n[0])
                          .take(2)
                          .join()
                          .toUpperCase(),
                      isActive: true,
                      joinDate: 'Jun 2026',
                      siteAccess: selectedSites,
                    );
                    setState(() => _users.add(newUser));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${nameCtrl.text} added as $selectedRole!',
                        ),
                        backgroundColor: const Color(0xFF21D19F),
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
                        'Add user',
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
          ),
        ),
      ),
    );
  }

  // EDIT USER SHEET
  void _showEditUserSheet(BuildContext context, AppUser user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    String selectedRole = user.role;
    List<String> selectedSites = List.from(user.siteAccess);
    bool isActive = user.isActive;
    final sites = ['All facilities', 'Site A', 'Site B', 'Site C'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF11151F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit user',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Color(0xFF7A8499)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Avatar
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _roleColor(selectedRole),
                          _roleColor(selectedRole).withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _sheetField('Full name', nameCtrl, Icons.person_outlined),
                const SizedBox(height: 12),
                _sheetField('Email', emailCtrl, Icons.email_outlined),
                const SizedBox(height: 16),

                // Active toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2433)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        color: Color(0xFF21D19F),
                        size: 14,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Active account',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      Switch(
                        value: isActive,
                        onChanged: (v) => setSheetState(() => isActive = v),
                        activeThumbColor: const Color(0xFF21D19F),
                        inactiveThumbColor: const Color(0xFF4B5563),
                        inactiveTrackColor: const Color(0xFF1E2433),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Role selector
                const Text(
                  'Role',
                  style: TextStyle(
                    color: Color(0xFF7A8499),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Admin', 'Technician', 'Viewer']
                      .map(
                        (r) => Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedRole = r),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedRole == r
                                    ? _roleColor(r).withValues(alpha: 0.2)
                                    : const Color(0xFF0B0E14),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedRole == r
                                      ? _roleColor(r)
                                      : const Color(0xFF1E2433),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _roleIcon(r),
                                    color: selectedRole == r
                                        ? _roleColor(r)
                                        : const Color(0xFF7A8499),
                                    size: 18,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    r,
                                    style: TextStyle(
                                      color: selectedRole == r
                                          ? _roleColor(r)
                                          : const Color(0xFF7A8499),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Site access
                const Text(
                  'Site access',
                  style: TextStyle(
                    color: Color(0xFF7A8499),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sites
                      .map(
                        (s) => GestureDetector(
                          onTap: () => setSheetState(() {
                            if (selectedSites.contains(s)) {
                              selectedSites.remove(s);
                            } else {
                              selectedSites.add(s);
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selectedSites.contains(s)
                                  ? const Color(
                                      0xFF21D19F,
                                    ).withValues(alpha: 0.2)
                                  : const Color(0xFF0B0E14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedSites.contains(s)
                                    ? const Color(0xFF21D19F)
                                    : const Color(0xFF1E2433),
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color: selectedSites.contains(s)
                                    ? const Color(0xFF21D19F)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dctx) => AlertDialog(
                              backgroundColor: const Color(0xFF11151F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                'Remove user?',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                'Remove ${user.name} from the system?',
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dctx),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Color(0xFF7A8499)),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _users.remove(user));
                                    Navigator.pop(dctx);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${user.name} removed'),
                                        backgroundColor: const Color(
                                          0xFFEF4444,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(color: Color(0xFFEF4444)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Remove',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                            return;
                          }
                          setState(() {
                            user.name = nameCtrl.text;
                            user.email = emailCtrl.text;
                            user.role = selectedRole;
                            user.siteAccess = selectedSites;
                            user.isActive = isActive;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${user.name} updated!'),
                              backgroundColor: const Color(0xFF21D19F),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF21D19F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Save changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2433)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
