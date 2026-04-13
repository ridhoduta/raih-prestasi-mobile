import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/notification.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? _studentId;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = await SessionService.getUser();
    if (user != null) {
      setState(() {
        _studentId = user.id;
      });
      await _fetchNotifications(refresh: true);
    }
  }

  Future<void> _fetchNotifications({bool refresh = false}) async {
    if (_studentId == null) return;
    
    final provider = context.read<NotificationProvider>();
    await provider.fetchNotifications(_studentId!, refresh: refresh);
    setState(() {
      _isFetchingMore = false;
    });
  }

  Future<void> _markAsRead(String? id) async {
    if (_studentId == null) return;
    await context.read<NotificationProvider>().markAsRead(_studentId!, notificationId: id);
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toUpperCase()) {
      case 'ACHIEVEMENT':
        icon = Icons.emoji_events_rounded;
        color = Colors.amber;
        break;
      case 'SUBMISSION':
        icon = Icons.assignment_turned_in_rounded;
        color = Colors.blue;
        break;
      case 'REGISTRATION':
        icon = Icons.app_registration_rounded;
        color = Colors.green;
        break;
      case 'INFO':
      default:
        icon = Icons.notifications_rounded;
        color = AppColors.primaryGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.notifications.any((n) => !n.isRead)) {
                return TextButton(
                  onPressed: () => _markAsRead(null),
                  child: const Text('Tandai Semua Dibaca'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return RefreshIndicator(
            onRefresh: () => _fetchNotifications(refresh: true),
            child: provider.notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationList(provider),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(
          Icons.notifications_none_outlined,
          size: 100,
          color: Colors.grey,
        ),
        const SizedBox(height: 24),
        Text(
          'Belum ada notifikasi',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Notifikasi terbaru akan muncul di sini',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationList(NotificationProvider provider) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isFetchingMore &&
            provider.hasMore &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          setState(() => _isFetchingMore = true);
          _fetchNotifications();
        }
        return true;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == provider.notifications.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
 
          final notification = provider.notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final timeStr = DateFormat('dd MMM yyyy, HH:mm').format(notification.createdAt);

    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          _markAsRead(notification.id);
        }
        // Logic to navigate based on type can be added here
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead ? null : Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                            color: notification.isRead ? Colors.black87 : Colors.black,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: notification.isRead ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[500],
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
}
