import 'package:flutter/material.dart';
import '../models/news.dart';
import '../models/announcement.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<News> _news = [];
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _error;

  List<News> get news => _news;
  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboardData({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getNews(limit: 5, forceRefresh: refresh),
        _apiService.getAnnouncements(limit: 3, forceRefresh: refresh),
      ]);
      
      _news = (results[0] as PaginatedResponse<News>).data;
      _announcements = (results[1] as PaginatedResponse<Announcement>).data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
