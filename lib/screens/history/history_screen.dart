import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/achievement.dart';
import '../../models/submission.dart';
import '../../models/competition.dart';
import '../../services/api_service.dart';
import '../../providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  final String studentId;
  final int initialIndex;

  const HistoryScreen({
    super.key,
    required this.studentId,
    this.initialIndex = 0,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final ScrollController _achievementScrollController = ScrollController();
  final ScrollController _submissionScrollController = ScrollController();
  final ScrollController _registrationScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Trigger FAB update
      }
    });

    // Setup scroll listeners for pagination
    _achievementScrollController.addListener(() {
      if (_achievementScrollController.position.pixels >=
          _achievementScrollController.position.maxScrollExtent - 200) {
        context.read<HistoryProvider>().fetchAchievements(studentId: widget.studentId);
      }
    });
    
    _submissionScrollController.addListener(() {
      if (_submissionScrollController.position.pixels >=
          _submissionScrollController.position.maxScrollExtent - 200) {
        context.read<HistoryProvider>().fetchSubmissions(studentId: widget.studentId);
      }
    });
    
    _registrationScrollController.addListener(() {
      if (_registrationScrollController.position.pixels >=
          _registrationScrollController.position.maxScrollExtent - 200) {
        context.read<HistoryProvider>().fetchRegistrations(studentId: widget.studentId);
      }
    });

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HistoryProvider>();
      provider.fetchAchievements(refresh: true, studentId: widget.studentId);
      provider.fetchSubmissions(refresh: true, studentId: widget.studentId);
      provider.fetchRegistrations(refresh: true, studentId: widget.studentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _achievementScrollController.dispose();
    _submissionScrollController.dispose();
    _registrationScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        title: const Text('Riwayat Saya'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: 'Prestasi'),
            Tab(text: 'Pengajuan'),
            Tab(text: 'Kompetisi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAchievementTab(),
          _buildSubmissionTab(),
          _buildCompetitionTab(),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        onPressed: _showAchievementBottomSheet,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Lapor Prestasi'),
      );
    } else if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        onPressed: _showSubmissionBottomSheet,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Pengajuan'),
      );
    }
    return null;
  }

  // --- TAB 1: PRESTASI (ACHIEVEMENT) ---

  Widget _buildAchievementTab() {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingAchievements && provider.achievements.isEmpty) {
          return _buildSkeletonList();
        }
        
        final items = provider.achievements.where((a) {
          final status = a.status.toUpperCase();
          return status == 'TERVERIFIKASI' || status == 'DITOLAK';
        }).toList();

        if (items.isEmpty && !provider.isLoadingAchievements) {
          return _buildEmptyState(
            'Belum Ada Prestasi',
            'Laporkan prestasimu sekarang juga!',
            Icons.emoji_events_outlined,
            _showAchievementBottomSheet,
            'Lapor Prestasi',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchAchievements(refresh: true, studentId: widget.studentId),
          color: AppColors.primaryGreen,
          child: ListView.builder(
            controller: _achievementScrollController,
            padding: const EdgeInsets.all(20),
            itemCount: items.length + (provider.hasMoreAchievements ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < items.length) {
                return _buildAchievementCard(items[index]);
              }
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAchievementCard(Achievement item) {
    Color statusColor;
    String statusLabel = item.status;

    switch (item.status.toUpperCase()) {
      case 'TERVERIFIKASI':
        statusColor = Colors.green;
        statusLabel = 'Terverifikasi';
        break;
      case 'DITOLAK':
        statusColor = Colors.red;
        statusLabel = 'Ditolak';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Menunggu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.competitionName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.result,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, color: AppColors.grey100),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (item.certificate != null)
                  const Icon(
                    Icons.card_membership_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: PENGAJUAN (SUBMISSION) ---

  Widget _buildSubmissionTab() {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingSubmissions && provider.submissions.isEmpty) {
          return _buildSkeletonList();
        }
        
        final items = provider.submissions.where((s) {
          final status = (s.status ?? '').toUpperCase();
          return status == 'DITERIMA' || status == 'DITOLAK' || status == 'MENUNGGU' || status == 'DISETUJUI';
        }).toList();

        if (items.isEmpty && !provider.isLoadingSubmissions) {
          return _buildEmptyState(
            'Belum Ada Pengajuan',
            'Ayo ajukan prestasi mandirimu!',
            Icons.assignment_rounded,
            _showSubmissionBottomSheet,
            'Tambah Pengajuan',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchSubmissions(refresh: true, studentId: widget.studentId),
          color: AppColors.primaryGreen,
          child: ListView.builder(
            controller: _submissionScrollController,
            padding: const EdgeInsets.all(20),
            itemCount: items.length + (provider.hasMoreSubmissions ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < items.length) {
                return _buildSubmissionCard(items[index]);
              }
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSubmissionCard(IndependentSubmission item) {
    Color statusColor;
    String status = (item.status ?? 'MENUNGGU').toUpperCase();

    switch (status) {
      case 'DITERIMA':
      case 'DISETUJUI':
        statusColor = AppColors.primaryGreen;
        status = 'DISETUJUI';
        break;
      case 'DITOLAK':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
        status = 'MENUNGGU';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == 'MENUNGGU')
                  IconButton(
                    onPressed: () => _confirmDeleteSubmission(item.id!),
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 22),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, color: AppColors.grey100),
            ),
            Text(
              item.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            if (item.documentUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 6),
                    const Text(
                      'Dokumen terlampir',
                      style: TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            if (status == 'DITOLAK' && item.rejectionNote != null && item.rejectionNote!.isNotEmpty)
              _buildNoteBox('Alasan Ditolak:', item.rejectionNote!, Colors.red.shade50, Colors.red.shade700, Colors.red.shade900),
            if (status == 'DISETUJUI' && item.recommendationLetter != null && item.recommendationLetter!.isNotEmpty)
              _buildRecommendationBox(item.recommendationLetter!),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: KOMPETISI (COMPETITION HISTORY) ---

  Widget _buildCompetitionTab() {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingRegistrations && provider.registrations.isEmpty) {
          return _buildSkeletonList();
        }
        
        final items = provider.registrations.where((r) =>
          r.status.toUpperCase() == 'DITERIMA' || r.status.toUpperCase() == 'DITOLAK'
        ).toList();

        if (items.isEmpty && !provider.isLoadingRegistrations) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(color: AppColors.lightGreenBg, shape: BoxShape.circle),
                  child: const Icon(Icons.history_rounded, size: 80, color: AppColors.primaryGreen),
                ),
                const SizedBox(height: 24),
                Text('Belum Ada Riwayat', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Belum ada kompetisi yang diterima atau ditolak.', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchRegistrations(refresh: true, studentId: widget.studentId),
          color: AppColors.primaryGreen,
          child: ListView.builder(
            controller: _registrationScrollController,
            padding: const EdgeInsets.all(20),
            itemCount: items.length + (provider.hasMoreRegistrations ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < items.length) {
                return _buildRegistrationCard(items[index]);
              }
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRegistrationCard(CompetitionRegistration item) {
    final isAccepted = item.status.toUpperCase() == 'DITERIMA';
    final statusColor = isAccepted ? Colors.green : Colors.red;
    final statusLabel = isAccepted ? 'Diterima' : 'Ditolak';
    final statusIcon = isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded;

    final title = item.competition?.title ?? 'Kompetisi Tidak Diketahui';
    final category = item.competition?.categoryName ?? '';
    final level = item.competition?.levelName ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(height: 1, color: AppColors.grey100)),
            if (category.isNotEmpty) _buildInfoRow(Icons.category_rounded, 'Kategori', category),
            if (level.isNotEmpty) _buildInfoRow(Icons.leaderboard_rounded, 'Tingkat', level),
            if (item.note != null && item.note!.isNotEmpty)
              _buildNoteBox('Catatan:', item.note!, AppColors.grey100, AppColors.textSecondary, AppColors.textPrimary),
          ],
        ),
      ),
    );
  }

  // --- HELPERS & COMMON WIDGETS ---

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => const HistorySkeletonCard(),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildNoteBox(String title, String content, Color bgColor, Color titleColor, Color contentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor)),
            const SizedBox(height: 4),
            Text(content, style: TextStyle(fontSize: 13, color: contentColor, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationBox(String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightGreenBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_rounded, size: 16, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Expanded(child: Text('Surat Rekomendasi Tersedia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryGreen))),
            IconButton(
              onPressed: () => launchUrl(Uri.parse(url)),
              icon: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primaryGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, VoidCallback onAction, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(color: AppColors.lightGreenBg, shape: BoxShape.circle),
            child: Icon(icon, size: 80, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          ElevatedButton.icon(onPressed: onAction, icon: const Icon(Icons.add_rounded), label: Text(label)),
        ],
      ),
    );
  }

  // --- BOTTOM SHEETS ---

  void _showAchievementBottomSheet() {
    final nameController = TextEditingController();
    final resultController = TextEditingController();
    String? certificateUrl;
    bool isUploading = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('Lapor Prestasi Baru', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Laporkan hasil lomba atau kompetisi yang telah kamu ikuti.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                _buildFieldLabel('Nama Kompetisi'),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Misal: Olimpiade Matematika Nasional'),
                  validator: (v) => v == null || v.isEmpty ? 'Nama kompetisi wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Hasil / Pencapaian'),
                TextFormField(
                  controller: resultController,
                  decoration: const InputDecoration(hintText: 'Misal: Juara 1 / Finalis'),
                  validator: (v) => v == null || v.isEmpty ? 'Hasil wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Sertifikat (Opsional)'),
                _buildFileUpload(
                  isUploading: isUploading,
                  url: certificateUrl,
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null && result.files.single.path != null) {
                      setModalState(() => isUploading = true);
                      try {
                        final url = await ApiService().uploadFile(result.files.single.path!);
                        setModalState(() { certificateUrl = url; isUploading = false; });
                      } catch (e) {
                        setModalState(() => isUploading = false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    }
                  }
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUploading ? null : () async {
                      if (formKey.currentState!.validate()) {
                        final achievement = Achievement(
                          id: '', studentId: widget.studentId,
                          competitionName: nameController.text, result: resultController.text,
                          certificate: certificateUrl, status: 'MENUNGGU', createdAt: DateTime.now(),
                        );
                        if (await ApiService().postAchievement(achievement)) {
                          if (mounted) {
                            Navigator.pop(context);
                            context.read<HistoryProvider>().fetchAchievements(refresh: true, studentId: widget.studentId);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil!'), backgroundColor: AppColors.primaryGreen));
                          }
                        }
                      }
                    },
                    child: const Text('Kirim Laporan'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubmissionBottomSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? documentUrl;
    bool isUploading = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('Lomba Mandiri', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Ajukan lomba di luar sekolah untuk pencatatan prestasi.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                _buildFieldLabel('Nama Lomba'),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: 'Misal: Lomba Debat Bahasa Inggris'),
                  validator: (v) => v == null || v.isEmpty ? 'Nama lomba wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Deskripsi Singkat'),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Jelaskan singkat tentang lomba ini...'),
                  validator: (v) => v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Dokumen / Sertifikat'),
                _buildFileUpload(
                  isUploading: isUploading,
                  url: documentUrl,
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null && result.files.single.path != null) {
                      setModalState(() => isUploading = true);
                      try {
                        final url = await ApiService().uploadFile(result.files.single.path!);
                        setModalState(() { documentUrl = url; isUploading = false; });
                      } catch (e) {
                        setModalState(() => isUploading = false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    }
                  }
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUploading ? null : () async {
                      if (formKey.currentState!.validate()) {
                        final sub = IndependentSubmission(
                          studentId: widget.studentId, title: titleController.text,
                          description: descController.text, documentUrl: documentUrl ?? '',
                        );
                        if (await ApiService().postSubmission(sub)) {
                          if (mounted) {
                            Navigator.pop(context);
                            context.read<HistoryProvider>().fetchSubmissions(refresh: true, studentId: widget.studentId);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil!'), backgroundColor: AppColors.primaryGreen));
                          }
                        }
                      }
                    },
                    child: const Text('Kirim Pengajuan'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFileUpload({required bool isUploading, String? url, required VoidCallback onTap}) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: url != null ? AppColors.primaryGreen : AppColors.grey200),
        ),
        child: Row(
          children: [
            Icon(
              isUploading ? Icons.cloud_upload_rounded : (url != null ? Icons.check_circle_rounded : Icons.file_present_rounded),
              color: url != null ? AppColors.primaryGreen : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isUploading ? 'Mengunggah...' : (url != null ? 'File diunggah' : 'Klik untuk unggah file'),
                style: TextStyle(color: url != null ? AppColors.primaryGreen : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSubmission(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pengajuan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan. Apakah kamu yakin?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tidak')),
          TextButton(
            onPressed: () async {
              if (await ApiService().deleteSubmission(id)) {
                if (mounted) {
                  Navigator.pop(context);
                  context.read<HistoryProvider>().fetchSubmissions(refresh: true, studentId: widget.studentId);
                }
              }
            },
            child: Text('Ya, Batalkan', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class HistorySkeletonCard extends StatefulWidget {
  const HistorySkeletonCard({super.key});

  @override
  State<HistorySkeletonCard> createState() => _HistorySkeletonCardState();
}

class _HistorySkeletonCardState extends State<HistorySkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.6).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(12))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 160, height: 16, color: AppColors.grey100),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 12, color: AppColors.grey100),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.grey100)),
              Container(width: 80, height: 24, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(20))),
            ],
          ),
        ),
      ),
    );
  }
}
