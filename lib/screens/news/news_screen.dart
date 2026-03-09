import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/news.dart';
import '../../models/api_response.dart';
import '../../services/api_service.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatelessWidget {
  final ApiService _apiService = ApiService();

  NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(title: const Text('Berita & Artikel')),
      body: FutureBuilder<PaginatedResponse<News>>(
        future: _apiService.getNews(),
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
                  ],
                ),
              ),
            );
          }
          final newsList = (snapshot.data?.data ?? [])
              .where((n) => n.isPublished)
              .toList();
          if (newsList.isEmpty) {
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
                      Icons.newspaper_rounded,
                      size: 80,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Berita',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cek kembali nanti untuk berita terbaru.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {}, // Handle refresh logic if needed
            color: AppColors.primaryGreen,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];
                return _buildNewsCard(context, news);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, News news) {
    final dateStr = DateFormat('dd MMM yyyy').format(news.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(news: news),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.thumbnail != null && news.thumbnail!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  news.thumbnail!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: double.infinity,
                    color: AppColors.lightGreenBg,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.primaryGreen,
                      size: 40,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.lightGreenBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Icon(
                  Icons.newspaper_rounded,
                  color: AppColors.primaryGreen,
                  size: 48,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'EDUKASI',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.circle,
                        size: 4,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
