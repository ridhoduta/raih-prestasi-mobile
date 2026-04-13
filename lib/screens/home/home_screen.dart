import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raih_prestasi_mobile/providers/notification_provider.dart';
import 'package:raih_prestasi_mobile/screens/profile/profile_screen.dart';
import '../notification/notification_screen.dart';
import '../../theme/app_theme.dart';
import '../activity/activity_screen.dart';
import '../competition/competition_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../score/score_screen.dart';
import '../announcement/announcement_screen.dart';
import '../history/history_screen.dart';
import '../../models/auth_response.dart';
import '../../services/session_service.dart';

class HomeScreen extends StatefulWidget {
  final StudentUser user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<Widget> _pages;
  late List<String> _titles;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardScreen(),
      CompetitionScreen(studentId: widget.user.id),
      AnnouncementScreen(),
      ActivityScreen(studentId: widget.user.id),
    ];
    _titles = ['Beranda', 'Kompetisi', 'Pengumuman', 'Aktivitas Saya'];
    
    // Fetch notifications on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications(widget.user.id, refresh: true);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return Badge(
                label: Text(provider.unreadCount.toString()),
                isLabelVisible: provider.unreadCount > 0,
                offset: const Offset(-4, 4),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Kompetisi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign_rounded),
            label: 'Pengumuman',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'Activity',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.backgroundBase,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryGreen),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppColors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: AppColors.primaryGreen,
              ),
            ),
            accountName: Text(
              widget.user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              "NISN: ${widget.user.nisn}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  Icons.person_outline,
                  Icons.person_rounded,
                  "Profil",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          studentId: widget.user.id,
                          name: widget.user.name,
                          nisn: widget.user.nisn,
                          kelas: widget.user.kelas,
                          angkatan: widget.user.angkatan,
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.history_rounded,
                  Icons.history_rounded,
                  "Riwayat Saya",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HistoryScreen(studentId: widget.user.id),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.analytics_outlined,
                  Icons.analytics_rounded,
                  "Nilai Akademik",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ScoreScreen(studentId: widget.user.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          _buildDrawerItem(
            Icons.logout_rounded,
            Icons.logout_rounded,
            "Keluar",
            () async {
              await SessionService.clearSession();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    IconData activeIcon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? AppColors.textPrimary.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
