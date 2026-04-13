import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/announcement.dart';
import '../../services/api_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String? announcementId;
  final Announcement? announcement;

  const AnnouncementDetailScreen({
    super.key,
    this.announcementId,
    this.announcement,
  });

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late Future<Announcement> _announcementFuture;

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _announcementFuture = Future.value(widget.announcement!);
    } else if (widget.announcementId != null) {
      _announcementFuture = ApiService().getAnnouncementById(widget.announcementId!);
    } else {
      _announcementFuture = Future.error('No announcement data or ID provided');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<Announcement>(
        future: _announcementFuture,
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
                      _announcementFuture = ApiService().getAnnouncementById(widget.announcementId!);
                    }),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final announcement = snapshot.data!;
          final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(announcement.createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengumuman Penting',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  announcement.title,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 24,
                    height: 1.2,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: AppColors.grey100, height: 1),
                ),
                Text(
                  announcement.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
