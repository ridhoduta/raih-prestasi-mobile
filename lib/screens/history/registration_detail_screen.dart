import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/competition.dart';
import '../../services/api_service.dart';

class RegistrationDetailScreen extends StatefulWidget {
  final String? registrationId;
  final CompetitionRegistration? registration;

  const RegistrationDetailScreen({
    super.key,
    this.registrationId,
    this.registration,
  });

  @override
  State<RegistrationDetailScreen> createState() => _RegistrationDetailScreenState();
}

class _RegistrationDetailScreenState extends State<RegistrationDetailScreen> {
  late Future<CompetitionRegistration> _registrationFuture;

  @override
  void initState() {
    super.initState();
    if (widget.registration != null) {
      _registrationFuture = Future.value(widget.registration!);
    } else if (widget.registrationId != null) {
      _registrationFuture = ApiService().getRegistrationById(widget.registrationId!);
    } else {
      _registrationFuture = Future.error('No registration data or ID provided');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        title: const Text('Detail Pendaftaran'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<CompetitionRegistration>(
        future: _registrationFuture,
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
                      _registrationFuture = ApiService().getRegistrationById(widget.registrationId!);
                    }),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final registration = snapshot.data!;
          final isAccepted = registration.status.toUpperCase() == 'DITERIMA';
          final statusColor = isAccepted ? Colors.green : Colors.red;
          final statusLabel = isAccepted ? 'Diterima' : 'Ditolak';
          final statusIcon = isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded;

          final competition = registration.competition;
          final title = competition?.title ?? 'Kompetisi Tidak Diketahui';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 64),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Status Pendaftaran',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Divider(height: 1, color: AppColors.grey200),
                ),
                Text(
                  'Informasi Kompetisi',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: title,
                  subtitle: '${(competition?.categoryName != null && competition!.categoryName.isNotEmpty) ? competition.categoryName : "-"} • ${(competition?.levelName != null && competition!.levelName.isNotEmpty) ? competition.levelName : "-"}',
                  icon: Icons.emoji_events_outlined,
                ),
                const SizedBox(height: 32),
                if (registration.note != null && registration.note!.isNotEmpty) ...[
                  Text(
                    'Catatan dari Admin/Guru',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Text(
                      registration.note!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        height: 1.6,
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

  Widget _buildInfoCard({required String title, required String subtitle, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
