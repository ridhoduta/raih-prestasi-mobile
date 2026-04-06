import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/news.dart';
import '../../models/announcement.dart';
import '../../providers/dashboard_provider.dart';
import '../news/news_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.news.isEmpty) {
          return _buildSkeletonDashboard();
        }

        if (provider.error != null && provider.news.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text('Gagal memuat data', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(provider.error!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadDashboardData(refresh: true),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadDashboardData(refresh: true),
          color: AppColors.primaryGreen,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              _buildSectionTitle("Pengumuman Terkini", Icons.campaign_rounded),
              if (provider.announcements.isEmpty)
                _buildEmptyState("Belum ada pengumuman.")
              else
                ...provider.announcements.map((ann) => _buildAnnouncementCard(ann)),
              const SizedBox(height: 24),
              _buildSectionTitle("Berita & Artikel", Icons.newspaper_rounded),
              if (provider.news.isEmpty)
                _buildEmptyState("Belum ada berita.")
              else
                ...provider.news.map((n) => _buildNewsCard(n)),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonDashboard() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        _buildSectionTitle("Pengumuman Terkini", Icons.campaign_rounded),
        const DashboardSkeletonCard(height: 120),
        const DashboardSkeletonCard(height: 120),
        const SizedBox(height: 24),
        _buildSectionTitle("Berita & Artikel", Icons.newspaper_rounded),
        const DashboardSkeletonCard(height: 200),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.lightGreenBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement ann) {
    return Card(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.lightGreenBg, borderRadius: BorderRadius.circular(30)),
                    child: const Text('PENTING', style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Text(DateFormat('dd MMM yyyy').format(ann.createdAt), style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 12),
              Text(ann.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(ann.content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(News news) {
    return Card(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: news.thumbnail != null ? Image.network(news.thumbnail!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder()) : _buildImagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('dd MMMM yyyy').format(news.createdAt), style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(news.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(news.content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Text("Selengkapnya", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 14)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryGreen),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(color: Colors.grey[100], child: const Center(child: Icon(Icons.image_outlined, size: 48, color: Colors.grey)));
  }
}

class DashboardSkeletonCard extends StatefulWidget {
  final double height;
  const DashboardSkeletonCard({super.key, required this.height});

  @override
  State<DashboardSkeletonCard> createState() => _DashboardSkeletonCardState();
}

class _DashboardSkeletonCardState extends State<DashboardSkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
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
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        height: widget.height,
        decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
