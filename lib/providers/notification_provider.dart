import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _nextCursor;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _nextCursor != null;
  String? get error => _error;

  Future<void> fetchNotifications(String studentId, {bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    if (refresh) {
      _isLoading = true;
      _nextCursor = null;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await _apiService.getNotifications(
        studentId,
        cursor: _nextCursor,
        forceRefresh: refresh,
      );

      if (refresh) {
        _notifications = response.data;
      } else {
        _notifications.addAll(response.data);
      }
      
      _nextCursor = response.nextCursor;
      
      // Calculate unread count from the list
      // Note: This only counts fetched notifications. 
      // In a real app, the BE should ideally return a total unread count.
      _updateUnreadCount();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String studentId, {String? notificationId}) async {
    try {
      final success = await _apiService.markNotificationsAsRead(
        studentId,
        notificationId: notificationId,
      );

      if (success) {
        if (notificationId == null) {
          // Mark all as read locally
          _notifications = _notifications.map((n) {
            return NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              isRead: true,
              createdAt: n.createdAt,
              studentId: n.studentId,
            );
          }).toList();
        } else {
          // Mark specific as read locally
          final index = _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            final n = _notifications[index];
            _notifications[index] = NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              isRead: true,
              createdAt: n.createdAt,
              studentId: n.studentId,
            );
          }
        }
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }
}
