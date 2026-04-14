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
import '../../widgets/activity_card.dart';
import '../../widgets/activity_skeleton.dart';

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

  String _selectedStatus = 'SEMUA';

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
        setState(() {
          _selectedStatus = 'SEMUA';
        }); // Trigger FAB update and reset filters
      }
    });

    // Setup scroll listeners for pagination
    _achievementScrollController.addListener(() {
      if (_achievementScrollController.position.pixels >=
          _achievementScrollController.position.maxScrollExtent - 200) {
        context.read<HistoryProvider>().fetchAchievements(
          studentId: widget.studentId,
        );
      }
    });

    _submissionScrollController.addListener(() {
      if (_submissionScrollController.position.pixels >=
          _submissionScrollController.position.maxScrollExtent - 200) {
        context.read<HistoryProvider>().fetchSubmissions(
          studentId: widget.studentId,
        );
      }
    });

    _registrationScrollController.addListener(() {
      if (_registrationScrollController.position.pixels >=
          _registrationScrollController.position.maxScrollExtent - 200) {
        context.read<HistoryProvider>().fetchRegistrations(
          studentId: widget.studentId,
        );
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              TabBar(
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
              _buildFilterChips(),
            ],
          ),
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
          final matchesStatus =
              _selectedStatus == 'SEMUA' ||
              (_selectedStatus == 'VERIFIED' && status == 'TERVERIFIKASI') ||
              (_selectedStatus == 'REJECTED' && status == 'DITOLAK') ||
              (_selectedStatus == 'WAITING' && status == 'MENUNGGU');

          return matchesStatus &&
              (status == 'TERVERIFIKASI' ||
                  status == 'DITOLAK' ||
                  status == 'MENUNGGU');
        }).toList();

        if (items.isEmpty && !provider.isLoadingAchievements) {
          return _buildEmptyState(
            'Belum Ada Prestasi',
            'Klaim prestasi yang telah kamu raih!',
            Icons.emoji_events_rounded,
            _showAchievementBottomSheet,
            'Lapor Prestasi',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchAchievements(
            refresh: true,
            studentId: widget.studentId,
          ),
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
    return AchievementActivityCard(achievement: item);
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
          final matchesStatus =
              _selectedStatus == 'SEMUA' ||
              (_selectedStatus == 'VERIFIED' &&
                  (status == 'DITERIMA' || status == 'DISETUJUI')) ||
              (_selectedStatus == 'REJECTED' && status == 'DITOLAK') ||
              (_selectedStatus == 'WAITING' && status == 'MENUNGGU');

          return matchesStatus &&
              (status == 'DITERIMA' ||
                  status == 'DITOLAK' ||
                  status == 'MENUNGGU' ||
                  status == 'DISETUJUI');
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
          onRefresh: () => provider.fetchSubmissions(
            refresh: true,
            studentId: widget.studentId,
          ),
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
    return SubmissionActivityCard(submission: item);
  }

  // --- TAB 3: KOMPETISI (COMPETITION HISTORY) ---

  Widget _buildCompetitionTab() {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingRegistrations && provider.registrations.isEmpty) {
          return _buildSkeletonList();
        }

        final items = provider.registrations.where((r) {
          final status = r.status.toUpperCase();
          final matchesStatus =
              _selectedStatus == 'SEMUA' ||
              (_selectedStatus == 'WAITING' && status == 'MENUNGGU') ||
              (_selectedStatus == 'VERIFIED' && status == 'DITERIMA') ||
              (_selectedStatus == 'REJECTED' && status == 'DITOLAK');

          return matchesStatus &&
              (status == 'DITERIMA' || status == 'DITOLAK' || status == 'MENUNGGU');
        }).toList();

        if (items.isEmpty && !provider.isLoadingRegistrations) {
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
                  'Belum Ada Riwayat',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada kompetisi yang diterima atau ditolak.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchRegistrations(
            refresh: true,
            studentId: widget.studentId,
          ),
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
    return RegistrationActivityCard(registration: item);
  }

  // --- HELPERS & COMMON WIDGETS ---

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => const ActivitySkeletonCard(),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onAction,
    String label, {
    bool showFab = true,
  }) {
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
            child: Icon(icon, size: 80, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          if (showFab) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(label),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final statusFilters = [
      {'label': 'Semua', 'value': 'SEMUA'},
      // {'label': 'Menunggu', 'value': 'WAITING'},
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
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: AppColors.grey100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onSearchChanged(String query) {
    // Search feature removed as per requirement
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
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Lapor Prestasi Baru',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Laporkan hasil lomba atau kompetisi yang telah kamu ikuti.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _buildFieldLabel('Nama Kompetisi'),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Misal: Olimpiade Matematika Nasional',
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Nama kompetisi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Hasil / Pencapaian'),
                TextFormField(
                  controller: resultController,
                  decoration: const InputDecoration(
                    hintText: 'Misal: Juara 1 / Finalis',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Hasil wajib diisi' : null,
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
                        final url = await ApiService().uploadFile(
                          result.files.single.path!,
                        );
                        setModalState(() {
                          certificateUrl = url;
                          isUploading = false;
                        });
                      } catch (e) {
                        setModalState(() => isUploading = false);
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    }
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUploading
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              final achievement = Achievement(
                                id: '',
                                studentId: widget.studentId,
                                competitionName: nameController.text,
                                result: resultController.text,
                                certificate: certificateUrl,
                                status: 'MENUNGGU',
                                createdAt: DateTime.now(),
                              );
                              if (await ApiService().postAchievement(
                                achievement,
                              )) {
                                if (mounted) {
                                  Navigator.pop(context);
                                  context
                                      .read<HistoryProvider>()
                                      .fetchAchievements(
                                        refresh: true,
                                        studentId: widget.studentId,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Berhasil!'),
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                  );
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
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Lomba Mandiri',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajukan lomba di luar sekolah untuk pencatatan prestasi.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _buildFieldLabel('Nama Lomba'),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Misal: Lomba Debat Bahasa Inggris',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nama lomba wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Deskripsi Singkat'),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan singkat tentang lomba ini...',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
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
                        final url = await ApiService().uploadFile(
                          result.files.single.path!,
                        );
                        setModalState(() {
                          documentUrl = url;
                          isUploading = false;
                        });
                      } catch (e) {
                        setModalState(() => isUploading = false);
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    }
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUploading
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              final sub = IndependentSubmission(
                                studentId: widget.studentId,
                                title: titleController.text,
                                description: descController.text,
                                documentUrl: documentUrl ?? '',
                              );
                              if (await ApiService().postSubmission(sub)) {
                                if (mounted) {
                                  Navigator.pop(context);
                                  context
                                      .read<HistoryProvider>()
                                      .fetchSubmissions(
                                        refresh: true,
                                        studentId: widget.studentId,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Berhasil!'),
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                  );
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
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFileUpload({
    required bool isUploading,
    String? url,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: url != null ? AppColors.primaryGreen : AppColors.grey200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUploading
                  ? Icons.cloud_upload_rounded
                  : (url != null
                        ? Icons.check_circle_rounded
                        : Icons.file_present_rounded),
              color: url != null
                  ? AppColors.primaryGreen
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isUploading
                    ? 'Mengunggah...'
                    : (url != null
                          ? 'File diunggah'
                          : 'Klik untuk unggah file'),
                style: TextStyle(
                  color: url != null
                      ? AppColors.primaryGreen
                      : AppColors.textSecondary,
                ),
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
        content: const Text(
          'Tindakan ini tidak dapat dibatalkan. Apakah kamu yakin?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () async {
              if (await ApiService().deleteSubmission(id)) {
                if (mounted) {
                  Navigator.pop(context);
                  context.read<HistoryProvider>().fetchSubmissions(
                    refresh: true,
                    studentId: widget.studentId,
                  );
                }
              }
            },
            child: Text(
              'Ya, Batalkan',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

