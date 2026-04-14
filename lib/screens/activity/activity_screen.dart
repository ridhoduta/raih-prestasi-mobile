import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/competition.dart';
import '../../models/submission.dart';
import '../../models/achievement.dart';
import '../../models/api_response.dart';
import '../../services/api_service.dart';
import '../../widgets/activity_card.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/activity_skeleton.dart';

class ActivityScreen extends StatefulWidget {
  final String studentId;

  const ActivityScreen({super.key, required this.studentId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final ApiService _apiService = ApiService();
  late Future<PaginatedResponse<CompetitionRegistration>> _registrationsFuture;
  late Future<PaginatedResponse<IndependentSubmission>> _submissionsFuture;
  late Future<PaginatedResponse<Achievement>> _achievementsFuture;

  String _selectedStatus = 'SEMUA';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _registrationsFuture = _apiService.getStudentRegistrations(
        widget.studentId,
      );
      _submissionsFuture = _apiService.getSubmissions(
        widget.studentId,
      );
      _achievementsFuture = _apiService.getAchievements(
        widget.studentId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundBase,
        appBar: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: AppColors.backgroundBase,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                const TabBar(
                  indicatorColor: AppColors.primaryGreen,
                  labelColor: AppColors.primaryGreen,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: 'Kompetisi'),
                    Tab(text: 'Pengajuan'),
                    Tab(text: 'Prestasi'),
                  ],
                ),
                _buildFilterChips(),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildKompetisiTab(),
            _buildPengajuanTab(),
            _buildPrestasiTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildKompetisiTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      color: AppColors.primaryGreen,
      child: FutureBuilder<PaginatedResponse<CompetitionRegistration>>(
        future: _registrationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 5,
              itemBuilder: (context, index) => const ActivitySkeletonCard(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allRegistrations = snapshot.data?.data ?? [];
          final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
          final registrations = allRegistrations.where((r) {
            final isRecent = r.createdAt.isAfter(oneWeekAgo);
            final status = r.status.toUpperCase();
            final matchesStatus = _selectedStatus == 'SEMUA' || 
                (_selectedStatus == 'WAITING' && status == 'MENUNGGU') ||
                (_selectedStatus == 'VERIFIED' && status == 'DITERIMA') ||
                (_selectedStatus == 'REJECTED' && status == 'DITOLAK');

            return isRecent && matchesStatus;
          }).toList();

          if (registrations.isEmpty) {
            return _buildPlaceholderTab(
              'Belum Ada Aktivitas',
              'Mulai jelajahi kompetisi dan daftarkan dirimu!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: registrations.length,
            itemBuilder: (context, index) {
              final reg = registrations[index];
              return _buildRegistrationCard(reg);
            },
          );
        },
      ),
    );
  }

  Widget _buildPengajuanTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      color: AppColors.primaryGreen,
      child: FutureBuilder<PaginatedResponse<IndependentSubmission>>(
        future: _submissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 5,
              itemBuilder: (context, index) => const ActivitySkeletonCard(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allSubmissions = snapshot.data?.data ?? [];
          final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
          final submissions = allSubmissions.where((s) {
            final isRecent = s.createdAt != null && s.createdAt!.isAfter(oneWeekAgo);
            final status = (s.status ?? '').toUpperCase();
            final matchesStatus = _selectedStatus == 'SEMUA' || 
                (_selectedStatus == 'WAITING' && status == 'MENUNGGU') ||
                (_selectedStatus == 'VERIFIED' && (status == 'DITERIMA' || status == 'DISETUJUI')) ||
                (_selectedStatus == 'REJECTED' && status == 'DITOLAK');

            return isRecent && matchesStatus;
          }).toList();

          if (submissions.isEmpty) {
            return _buildPlaceholderTab(
              'Belum Ada Pengajuan',
              'Ajukan kompetisi mandiri kamu di sini!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final sub = submissions[index];
              return _buildPengajuanCard(sub);
            },
          );
        },
      ),
    );
  }

  Widget _buildPengajuanCard(IndependentSubmission sub) {
    return SubmissionActivityCard(submission: sub);
  }

  Widget _buildPrestasiTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      color: AppColors.primaryGreen,
      child: FutureBuilder<PaginatedResponse<Achievement>>(
        future: _achievementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 5,
              itemBuilder: (context, index) => const ActivitySkeletonCard(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allAchievements = snapshot.data?.data ?? [];
          final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
          final achievements = allAchievements.where((a) {
            final isRecent = a.createdAt.isAfter(oneWeekAgo);
            final status = a.status.toUpperCase();
            final matchesStatus = _selectedStatus == 'SEMUA' || 
                (_selectedStatus == 'WAITING' && status == 'MENUNGGU') ||
                (_selectedStatus == 'VERIFIED' && status == 'TERVERIFIKASI') ||
                (_selectedStatus == 'REJECTED' && status == 'DITOLAK');

            return isRecent && matchesStatus;
          }).toList();

          if (achievements.isEmpty) {
            return _buildPlaceholderTab(
              'Belum Ada Prestasi',
              'Laporkan prestasi gemilangmu sekarang!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _buildPrestasiCard(achievement);
            },
          );
        },
      ),
    );
  }

  Widget _buildPrestasiCard(Achievement achievement) {
    return AchievementActivityCard(achievement: achievement);
  }

  Widget _buildPlaceholderTab(String title, String subtitle, {IconData? icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: AppColors.lightGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.hourglass_empty_rounded,
              size: 80,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final statusFilters = [
      {'label': 'Semua', 'value': 'SEMUA'},
      {'label': 'Menunggu', 'value': 'WAITING'},
      {'label': 'Disetujui', 'value': 'VERIFIED'},
      {'label': 'Ditolak', 'value': 'REJECTED'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statusFilters.length,
        itemBuilder: (context, index) {
          final filter = statusFilters[index];
          final isSelected = _selectedStatus == filter['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = filter['value']!;
                });
              },
              selectedColor: AppColors.primaryGreen.withOpacity(0.1),
              checkmarkColor: AppColors.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: AppColors.grey100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegistrationCard(CompetitionRegistration reg) {
    return RegistrationActivityCard(registration: reg);
  }

  void _showNoteDialog(String note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catatan Penyelenggara'),
        content: Text(note, style: const TextStyle(height: 1.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
