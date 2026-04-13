import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/achievement.dart';
import '../../services/api_service.dart';

class AchievementDetailScreen extends StatefulWidget {
  final String? achievementId;
  final Achievement? achievement;

  const AchievementDetailScreen({
    super.key,
    this.achievementId,
    this.achievement,
  });

  @override
  State<AchievementDetailScreen> createState() => _AchievementDetailScreenState();
}

class _AchievementDetailScreenState extends State<AchievementDetailScreen> {
  late Future<Achievement> _achievementFuture;

  @override
  void initState() {
    super.initState();
    if (widget.achievement != null) {
      _achievementFuture = Future.value(widget.achievement!);
    } else if (widget.achievementId != null) {
      _achievementFuture = ApiService().getAchievementById(widget.achievementId!);
    } else {
      _achievementFuture = Future.error('No achievement data or ID provided');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        title: const Text('Detail Prestasi'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<Achievement>(
        future: _achievementFuture,
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
                      _achievementFuture = ApiService().getAchievementById(widget.achievementId!);
                    }),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final achievement = snapshot.data!;
          final dateStr = DateFormat('dd MMMM yyyy').format(achievement.createdAt);

          Color statusColor;
          String statusLabel = achievement.status;

          switch (achievement.status.toUpperCase()) {
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.primaryGreen,
                      size: 60,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoSection('Nama Kompetisi', achievement.competitionName),
                _buildInfoSection('Pencapaian', achievement.result),
                _buildInfoSection('Tanggal Lapor', dateStr),
                if (achievement.certificate != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Sertifikat',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse(achievement.certificate!)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.card_membership_rounded, color: AppColors.primaryGreen),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Lihat Sertifikat',
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
                ],
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
