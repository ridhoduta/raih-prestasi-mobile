import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/submission.dart';
import '../../models/api_response.dart';
import '../../services/api_service.dart';

class SubmissionScreen extends StatefulWidget {
  final String studentId;
  const SubmissionScreen({super.key, required this.studentId});

  @override
  _SubmissionScreenState createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final ApiService _apiService = ApiService();
  late Future<PaginatedResponse<IndependentSubmission>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshSubmissions();
  }

  void _refreshSubmissions() {
    setState(() {
      _submissionsFuture = _apiService.getSubmissions(widget.studentId);
    });
  }

  void _showAddBottomSheet() {
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
                  'Ajukan lomba yang kamu ikuti di luar sekolah untuk pencatatan prestasi.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                Text(
                  'Nama Lomba',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText:
                        'Misal: Lomba Debat Bahasa Inggris Se-Jabodetabek',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nama lomba wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                Text(
                  'Deskripsi Singkat',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
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

                Text(
                  'Dokumen / Sertifikat',
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
                                documentUrl = url;
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
                        color: documentUrl != null
                            ? AppColors.primaryGreen
                            : AppColors.grey200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUploading
                              ? Icons.cloud_upload_rounded
                              : (documentUrl != null
                                    ? Icons.check_circle_rounded
                                    : Icons.file_present_rounded),
                          color: documentUrl != null
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isUploading
                                ? 'Mengunggah...'
                                : (documentUrl != null
                                      ? 'Dokumen diunggah'
                                      : 'Klik untuk unggah dokumen'),
                            style: TextStyle(
                              color: documentUrl != null
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
                              final submission = IndependentSubmission(
                                studentId: widget.studentId,
                                title: titleController.text,
                                description: descController.text,
                                documentUrl: documentUrl ?? '',
                              );
                              final success = await _apiService.postSubmission(
                                submission,
                              );
                              if (success) {
                                Navigator.pop(context);
                                _refreshSubmissions();
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pengajuan berhasil dikirim',
                                      ),
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                  );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(title: const Text('Pengajuan Mandiri')),
      body: FutureBuilder<PaginatedResponse<IndependentSubmission>>(
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
                      onPressed: _refreshSubmissions,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = (snapshot.data?.data ?? []).where((s) {
            final status = (s.status ?? '').toUpperCase();
            return status == 'DITERIMA' || status == 'DITOLAK';
          }).toList();
          if (items.isEmpty) {
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
                      Icons.assignment_rounded,
                      size: 80,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Pengajuan',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ayo ajukan prestasi mandirimu!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showAddBottomSheet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Pengajuan'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshSubmissions(),
            color: AppColors.primaryGreen,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildSubmissionCard(item);
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

  Widget _buildSubmissionCard(IndependentSubmission item) {
    Color statusColor;
    String status = (item.status ?? 'MENUNGGU').toUpperCase();

    switch (status) {
      case 'DISETUJUI':
        statusColor = AppColors.primaryGreen;
        break;
      case 'DITOLAK':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
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
                    ],
                  ),
                ),
                if (status == 'MENUNGGU')
                  IconButton(
                    onPressed: () => _confirmDelete(item.id!),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade300,
                      size: 22,
                    ),
                    tooltip: 'Batalkan',
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            if (item.documentUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 14,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dokumen lampirkan',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            // Rejection note when DITOLAK
            if (status == 'DITOLAK' &&
                item.rejectionNote != null &&
                item.rejectionNote!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alasan Ditolak:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.rejectionNote!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade900,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Recommendation letter when DITERIMA
            if (status == 'DITERIMA' &&
                item.recommendationLetter != null &&
                item.recommendationLetter!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_rounded,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Surat Rekomendasi Tersedia',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          launchUrl(Uri.parse(item.recommendationLetter!));
                        },
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
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
              if (await _apiService.deleteSubmission(id)) {
                Navigator.pop(context);
                _refreshSubmissions();
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
