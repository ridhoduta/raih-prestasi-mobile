import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/competition.dart';
import '../../providers/competition_provider.dart';
import 'competition_detail_screen.dart';
import 'competition_registration_screen.dart';

class CompetitionScreen extends StatefulWidget {
  final String studentId;

  const CompetitionScreen({super.key, required this.studentId});

  @override
  State<CompetitionScreen> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends State<CompetitionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompetitionProvider>().fetchCompetitions(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<CompetitionProvider>().fetchCompetitions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilterHeader(),
          Expanded(
            child: Consumer<CompetitionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.competitions.isEmpty) {
                  return _buildSkeletonList();
                }

                if (provider.competitions.isEmpty) {
                  return _buildEmptyWidget();
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchCompetitions(refresh: true),
                  color: AppColors.primaryGreen,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: provider.competitions.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < provider.competitions.length) {
                        return _buildCompetitionCard(provider.competitions[index]);
                      }
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    final provider = context.watch<CompetitionProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: (val) => provider.updateFilters(search: val),
            decoration: InputDecoration(
              hintText: 'Cari kompetisi impianmu...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        size: 20,
                        color: AppColors.grey400,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        provider.updateFilters(search: '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildFilterDropdown(
                  label: 'KATEGORI',
                  value: provider.category,
                  items: provider.categories,
                  onChanged: (val) => provider.updateFilters(category: val),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  label: 'TINGKAT',
                  value: provider.level,
                  items: provider.levels,
                  onChanged: (val) => provider.updateFilters(level: val),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  label: 'STATUS',
                  value: provider.status,
                  items: const ['Semua', 'Aktif', 'Tidak Aktif'],
                  onChanged: (val) => provider.updateFilters(status: val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final bool isSelected = value != 'Semua';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.lightGreenBg : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen
                  : AppColors.grey400.withOpacity(0.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: value == item
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected && value == item
                          ? AppColors.primaryGreen
                          : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
              ),
              isDense: true,
              dropdownColor: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitionCard(Competition competition) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final dateRange =
        '${dateFormat.format(competition.startDate)} - ${dateFormat.format(competition.endDate)}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompetitionDetailScreen(
                competition: competition,
                studentId: widget.studentId,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child:
                  competition.thumbnail != null &&
                      competition.thumbnail!.isNotEmpty
                  ? Image.network(
                      competition.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildBadge(
                          competition.categoryName,
                          AppColors.lightGreenBg,
                          AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          competition.levelName,
                          const Color(0xFFFFF3E0),
                          Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          competition.isActive ? 'Aktif' : 'Tutup',
                          competition.isActive
                              ? const Color(0xFFE3F2FD)
                              : const Color(0xFFFFEBEE),
                          competition.isActive
                              ? Colors.blue.shade800
                              : Colors.red.shade800,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    competition.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  if (competition.description != null)
                    Text(
                      competition.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateRange,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompetitionRegistrationScreen(
                              competition: competition,
                              studentId: widget.studentId,
                            ),
                          ),
                        );
                      },
                      child: const Text('Daftar Sekarang'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.emoji_events_outlined,
          size: 48,
          color: Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => const CompetitionSkeletonCard(),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'Tidak ada kompetisi ditemukan',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba gunakan kata kunci atau filter lain.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class CompetitionSkeletonCard extends StatefulWidget {
  const CompetitionSkeletonCard({super.key});

  @override
  State<CompetitionSkeletonCard> createState() => _CompetitionSkeletonCardState();
}

class _CompetitionSkeletonCardState extends State<CompetitionSkeletonCard>
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
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: Container(color: AppColors.grey100)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 80, height: 24, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(20))),
                      const SizedBox(width: 8),
                      Container(width: 60, height: 24, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(20))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(width: double.infinity, height: 24, color: AppColors.grey100),
                  const SizedBox(height: 8),
                  Container(width: 200, height: 24, color: AppColors.grey100),
                  const SizedBox(height: 20),
                  Container(width: double.infinity, height: 48, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(12))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
