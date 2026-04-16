import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/academic_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/student_academic.dart';
import '../../models/academic_score.dart';
import '../../models/achievement.dart';

class AcademicScreen extends StatefulWidget {
  const AcademicScreen({super.key});

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid fetching during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AcademicProvider>(context, listen: false);
      if (provider.students.isEmpty) {
        provider.fetchAcademicData();
      }
      _searchController.text = provider.searchQuery;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        title: const Text('Data Akademik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AcademicProvider>(context, listen: false).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(context),
          Expanded(
            child: Consumer<AcademicProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text('Terjadi Kesalahan', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: provider.refresh,
                            child: const Text('Coba Lagi'),
                          )
                        ],
                      ),
                    ),
                  );
                }

                if (provider.students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: AppColors.lightGreenBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_outlined, size: 64, color: AppColors.primaryGreen),
                        ),
                        const SizedBox(height: 16),
                        Text('Tidak ada data', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Coba ubah filter atau pencarian Anda',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: provider.refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24, left: 16, right: 16),
                    itemCount: provider.students.length,
                    itemBuilder: (context, index) {
                      final student = provider.students[index];
                      return _buildStudentCard(context, student);
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

  Widget _buildFilterSection(BuildContext context) {
    final provider = Provider.of<AcademicProvider>(context);

    // Generate upcoming/past years for dropdown
    final currentYear = DateTime.now().year;
    List<String> yearOptions = [];
    for (int i = -2; i <= 1; i++) {
      int start = currentYear + i;
      yearOptions.add('$start/${start + 1}');
    }

    if (!yearOptions.contains(provider.academicYear)) {
      yearOptions.add(provider.academicYear);
      yearOptions.sort();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama atau NISN...',
              prefixIcon: const Icon(Icons.search, color: AppColors.grey400),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.grey400),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (value) {
              provider.setSearchQuery(value);
            },
          ),
          const SizedBox(height: 12),
          // Dropdowns
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Tahun Ajaran',
                  value: provider.academicYear,
                  items: yearOptions,
                  onChanged: (value) {
                    if (value != null) {
                      provider.setFilter(value, provider.semester);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Semester',
                  value: provider.semester,
                  items: ['GANJIL', 'GENAP'],
                  onChanged: (value) {
                    if (value != null) {
                      provider.setFilter(provider.academicYear, value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGreen),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentAcademic student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: AppColors.primaryGreen,
        collapsedIconColor: AppColors.grey400,
        leading: CircleAvatar(
          backgroundColor: AppColors.lightGreenBg,
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'NISN: ${student.nisn} ${student.kelas != null ? '- Kelas: ${student.kelas}' : ''}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        children: [
          const Divider(height: 1),
          // Scores Section
          if (student.academicScores.isNotEmpty)
            _buildSection(
              context,
              title: 'Nilai Akademik',
              icon: Icons.menu_book,
              child: Column(
                children: student.academicScores.map((score) => _buildScoreItem(score)).toList(),
              ),
            )
          else
            _buildEmptyState('Belum ada nilai akademik'),

          // Achievements Section
          if (student.achievements.isNotEmpty)
            _buildSection(
              context,
              title: 'Prestasi',
              icon: Icons.emoji_events,
              child: Column(
                children: student.achievements.map((ach) => _buildAchievementItem(ach)).toList(),
              ),
            )
          else
            _buildEmptyState('Belum ada data prestasi'),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildScoreItem(AcademicScore score) {
    Color scoreColor = _getScoreColor(score.score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              score.subject,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              score.score.toStringAsFixed(0),
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.competitionName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                if (achievement.result.isNotEmpty)
                  Text(
                    '${achievement.result} • ${achievement.points ?? 0} Point',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.grey400),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.primaryGreen;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}
