import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/submission.dart';
import '../../services/api_service.dart';

class SubmissionDetailScreen extends StatefulWidget {
  final String? submissionId;
  final IndependentSubmission? submission;

  const SubmissionDetailScreen({
    super.key,
    this.submissionId,
    this.submission,
  });

  @override
  State<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  late Future<IndependentSubmission> _submissionFuture;

  @override
  void initState() {
    super.initState();
    if (widget.submission != null) {
      _submissionFuture = Future.value(widget.submission!);
    } else if (widget.submissionId != null) {
      _submissionFuture = ApiService().getSubmissionById(widget.submissionId!);
    } else {
      _submissionFuture = Future.error('No submission data or ID provided');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        title: const Text('Detail Pengajuan'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<IndependentSubmission>(
        future: _submissionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text('Gagal memuat data', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _submissionFuture = ApiService().getSubmissionById(widget.submissionId!);
                    }),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final submission = snapshot.data!;
          final dateStr = submission.createdAt != null 
              ? DateFormat('dd MMMM yyyy').format(submission.createdAt!)
              : '-';

          Color statusColor;
          String status = (submission.status ?? 'MENUNGGU').toUpperCase();

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            submission.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(height: 1, color: AppColors.grey100),
                ),
                _buildInfoSection('Deskripsi', submission.description ?? '-'),
                _buildInfoSection('Tanggal Pengajuan', dateStr),
                
                if (submission.documentUrl.isNotEmpty) ...[
                  const Text(
                    'Dokumen Lampiran',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse(submission.documentUrl)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, color: AppColors.primaryGreen),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Lihat Dokumen',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primaryGreen),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (status == 'DITOLAK' && submission.rejectionNote != null && submission.rejectionNote!.isNotEmpty)
                  _buildNoteBox('Alasan Ditolak:', submission.rejectionNote!, Colors.red.shade50, Colors.red.shade700, Colors.red.shade900),
                
                if (status == 'DISETUJUI' && submission.recommendationLetter != null && submission.recommendationLetter!.isNotEmpty)
                  _buildRecommendationBox(submission.recommendationLetter!),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteBox(String title, String content, Color bgColor, Color titleColor, Color contentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 14, color: contentColor, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRecommendationBox(String url) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.lightGreenBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_rounded, color: AppColors.primaryGreen),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Surat Rekomendasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  SizedBox(height: 4),
                  Text('Klik untuk mengunduh/melihat', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
                ],
              ),
            ),
            const Icon(Icons.download_rounded, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }
}
