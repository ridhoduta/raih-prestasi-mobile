import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/competition.dart';
import '../../models/submission.dart';
import '../../models/achievement.dart';
import '../../models/api_response.dart';
import '../../services/api_service.dart';

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
      _submissionsFuture = _apiService.getSubmissions(widget.studentId);
      _achievementsFuture = _apiService.getAchievements(widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundBase,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundBase,
          elevation: 0,
          toolbarHeight: 0,
          centerTitle: false,
          bottom: const TabBar(
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
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
          final registrations = allRegistrations
              .where((r) => r.createdAt.isAfter(oneWeekAgo))
              .toList();

          if (registrations.isEmpty) {
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
                    child: const Icon(
                      Icons.history_rounded,
                      size: 80,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Aktivitas',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai jelajahi kompetisi dan daftarkan dirimu!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
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
          final submissions = allSubmissions
              .where(
                (s) => s.createdAt != null && s.createdAt!.isAfter(oneWeekAgo),
              )
              .toList();

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
    final statusColor = _getStatusColor(sub.status ?? 'MENUNGGU');
    final statusBg = statusColor.withOpacity(0.1);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.assignment_ind_rounded,
                    color: AppColors.primaryGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(sub.createdAt ?? DateTime.now()),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if ((sub.description != null && sub.description!.isNotEmpty) ||
              sub.documentUrl.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.grey100),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sub.description != null &&
                      sub.description!.isNotEmpty) ...[
                    const Text(
                      'Keterangan',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  if (sub.documentUrl.isNotEmpty) ...[
                    if (sub.description != null && sub.description!.isNotEmpty)
                      const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          size: 14,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Dokumen terlampir',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const Divider(height: 1, color: AppColors.grey100),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    (sub.status ?? 'MENUNGGU').toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (sub.rejectionNote != null &&
                        sub.rejectionNote!.isNotEmpty)
                      IconButton(
                        onPressed: () => _showNoteDialog(sub.rejectionNote!),
                        icon: const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        tooltip: 'Lihat Alasan Penolakan',
                      ),
                    if (sub.recommendationLetter != null &&
                        sub.recommendationLetter!.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          launchUrl(Uri.parse(sub.recommendationLetter!));
                        },
                        icon: const Icon(
                          Icons.file_download_rounded,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                        tooltip: 'Unduh Surat Rekomendasi',
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

  Widget _buildPrestasiTab() {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      color: AppColors.primaryGreen,
      child: FutureBuilder<PaginatedResponse<Achievement>>(
        future: _achievementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
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
          final achievements = allAchievements
              .where((a) => a.createdAt.isAfter(oneWeekAgo))
              .toList();

          if (achievements.isEmpty) {
            return _buildPlaceholderTab(
              'Belum Ada Prestasi',
              'Klaim prestasi yang telah kamu raih!',
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
    final statusColor = _getStatusColor(achievement.status);
    final statusBg = statusColor.withOpacity(0.1);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.primaryGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.competitionName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        achievement.result,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(achievement.createdAt),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (achievement.certificate != null &&
              achievement.certificate!.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.grey100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.card_membership_rounded,
                    size: 14,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Sertifikat terlampir',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1, color: AppColors.grey100),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    achievement.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (achievement.certificate != null &&
                    achievement.certificate!.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      launchUrl(Uri.parse(achievement.certificate!));
                    },
                    icon: const Icon(
                      Icons.card_membership_rounded,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                    tooltip: 'Lihat Sertifikat',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, String subtitle) {
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
            child: const Icon(
              Icons.hourglass_empty_rounded,
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

  Widget _buildRegistrationCard(CompetitionRegistration reg) {
    final competition = reg.competition;
    final statusColor = _getStatusColor(reg.status);
    final statusBg = statusColor.withOpacity(0.1);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      competition?.thumbnail != null &&
                          competition!.thumbnail!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            competition.thumbnail!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.primaryGreen,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        competition?.title ?? 'Kompetisi',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(reg.createdAt),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey100),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text(
                'Detail Pendaftaran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 20),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reg.answers != null)
                  ...reg.answers!.map(
                    (ans) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ans.fieldLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ans.value.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey100),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    reg.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (reg.note != null && reg.note!.isNotEmpty)
                  IconButton(
                    onPressed: () => _showNoteDialog(reg.note!),
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                    tooltip: 'Lihat Catatan',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'MENUNGGU':
        return Colors.orange.shade700;
      case 'DISETUJUI':
      case 'TERVERIFIKASI':
        return AppColors.primaryGreen;
      case 'DITOLAK':
        return Colors.red.shade700;
      default:
        return AppColors.textSecondary;
    }
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
