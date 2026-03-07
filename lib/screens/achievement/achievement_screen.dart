import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/achievement.dart';
import '../../services/api_service.dart';

class AchievementScreen extends StatefulWidget {
  final String studentId;
  const AchievementScreen({super.key, required this.studentId});

  @override
  _AchievementScreenState createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Achievement>> _achievementsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAchievements();
  }

  void _refreshAchievements() {
    setState(() {
      _achievementsFuture = _apiService.getAchievements(widget.studentId);
    });
  }

  void _showAddBottomSheet() {
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

                Text(
                  'Nama Kompetisi',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
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

                Text(
                  'Hasil / Pencapaian',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: resultController,
                  decoration: const InputDecoration(
                    hintText: 'Misal: Juara 1 / Finalis',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Hasil wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                Text(
                  'Sertifikat (Opsional)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: isUploading
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles();
                          if (result != null &&
                              result.files.single.path != null) {
                            setModalState(() => isUploading = true);
                            try {
                              final url = await _apiService.uploadFile(
                                result.files.single.path!,
                              );
                              setModalState(() {
                                certificateUrl = url;
                                isUploading = false;
                              });
                            } catch (e) {
                              setModalState(() => isUploading = false);
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal unggah: $e')),
                                );
                            }
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: certificateUrl != null
                            ? AppColors.primaryGreen
                            : AppColors.grey200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUploading
                              ? Icons.cloud_upload_rounded
                              : (certificateUrl != null
                                    ? Icons.check_circle_rounded
                                    : Icons.file_present_rounded),
                          color: certificateUrl != null
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isUploading
                                ? 'Mengunggah...'
                                : (certificateUrl != null
                                      ? 'Sertifikat dipilih'
                                      : 'Pilih file sertifikat'),
                            style: TextStyle(
                              color: certificateUrl != null
                                  ? AppColors.primaryGreen
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                              final success = await _apiService.postAchievement(
                                achievement,
                              );
                              if (success) {
                                Navigator.pop(context);
                                _refreshAchievements();
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Laporan berhasil dikirim'),
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                  );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prestasi Saya')),
      body: FutureBuilder<List<Achievement>>(
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
                padding: const EdgeInsets.all(24.0),
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
                      'Terjadi kesalahan',
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
                      onPressed: _refreshAchievements,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = (snapshot.data ?? [])
              .where((a) => a.status.toUpperCase() == 'TERVERIFIKASI')
              .toList();
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      size: 80,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Prestasi',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Laporkan prestasimu sekarang juga!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showAddBottomSheet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Lapor Prestasi'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshAchievements(),
            color: AppColors.primaryGreen,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildAchievementCard(item);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBottomSheet,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
}
