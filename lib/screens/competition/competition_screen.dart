import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/competition.dart';
import '../../services/api_service.dart';
import 'competition_detail_screen.dart';
import 'competition_registration_screen.dart';

class CompetitionScreen extends StatefulWidget {
  final String studentId;

  const CompetitionScreen({super.key, required this.studentId});

  @override
  State<CompetitionScreen> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends State<CompetitionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Competition> _allCompetitions = [];
  List<Competition> _filteredCompetitions = [];
  bool _isLoading = true;
  String? _error;

  String _selectedCategory = 'Semua';
  String _selectedLevel = 'Semua';
  String _selectedStatus = 'Semua';

  List<String> _categories = ['Semua'];
  List<String> _levels = ['Semua'];
  final List<String> _statuses = ['Semua', 'Aktif', 'Tidak Aktif'];

  @override
  void initState() {
    super.initState();
    _fetchCompetitions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCompetitions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final competitions = await _apiService.getActiveCompetitions();
      setState(() {
        _allCompetitions = competitions;
        _filteredCompetitions = competitions;

        _categories = [
          'Semua',
          ..._allCompetitions.map((e) => e.categoryName).toSet().toList(),
        ];
        _levels = [
          'Semua',
          ..._allCompetitions.map((e) => e.levelName).toSet().toList(),
        ];

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredCompetitions = _allCompetitions.where((comp) {
        final matchesSearch =
            comp.title.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            (comp.description?.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ??
                false);

        final matchesCategory =
            _selectedCategory == 'Semua' ||
            comp.categoryName == _selectedCategory;
        final matchesLevel =
            _selectedLevel == 'Semua' || comp.levelName == _selectedLevel;

        bool matchesStatus = true;
        if (_selectedStatus == 'Aktif') {
          matchesStatus = comp.isActive;
        } else if (_selectedStatus == 'Tidak Aktif') {
          matchesStatus = !comp.isActive;
        }

        return matchesSearch &&
            matchesCategory &&
            matchesLevel &&
            matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilterHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : _error != null
                ? _buildErrorWidget()
                : _filteredCompetitions.isEmpty
                ? _buildEmptyWidget()
                : RefreshIndicator(
                    onRefresh: _fetchCompetitions,
                    color: AppColors.primaryGreen,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: _filteredCompetitions.length,
                      itemBuilder: (context, index) {
                        final competition = _filteredCompetitions[index];
                        return _buildCompetitionCard(competition);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
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
                      onPressed: () => _searchController.clear(),
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
                  value: _selectedCategory,
                  items: _categories,
                  onChanged: (val) {
                    setState(() => _selectedCategory = val!);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  label: 'TINGKAT',
                  value: _selectedLevel,
                  items: _levels,
                  onChanged: (val) {
                    setState(() => _selectedLevel = val!);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  label: 'STATUS',
                  value: _selectedStatus,
                  items: _statuses,
                  onChanged: (val) {
                    setState(() => _selectedStatus = val!);
                    _applyFilters();
                  },
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

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Terjadi kesalahan',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchCompetitions,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
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
