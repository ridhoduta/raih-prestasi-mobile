import 'package:flutter/material.dart';
import '../models/competition.dart';
import '../services/api_service.dart';

class CompetitionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Competition> _competitions = [];
  String? _cursor;
  bool _isLoading = false;
  bool _hasMore = true;

  // Filters
  String _search = '';
  String _category = 'Semua';
  String _level = 'Semua';
  String _status = 'Semua';

  List<Competition> get competitions => _competitions;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  String get search => _search;
  String get category => _category;
  String get level => _level;
  String get status => _status;

  // Metadata for filters
  List<String> _categories = ['Semua'];
  List<String> _levels = ['Semua'];
  List<String> get categories => _categories;
  List<String> get levels => _levels;

  void updateFilters({String? search, String? category, String? level, String? status}) {
    if (search != null) _search = search;
    if (category != null) _category = category;
    if (level != null) _level = level;
    if (status != null) _status = status;
    fetchCompetitions(refresh: true);
  }

  Future<void> fetchCompetitions({bool refresh = false}) async {
    if (_isLoading || (!refresh && !_hasMore)) return;

    _isLoading = true;
    if (refresh) {
      _cursor = null;
      _hasMore = true;
    }
    notifyListeners();

    try {
      final res = await _apiService.getActiveCompetitions(
        cursor: _cursor,
        search: _search.isEmpty ? null : _search,
        forceRefresh: refresh,
      );
      
      if (refresh) _competitions = [];
      
      // Apply local client-side filters if needed (if API doesn't support category/level/status yet)
      final newItems = res.data.where((comp) {
        final matchesCategory = _category == 'Semua' || comp.categoryName == _category;
        final matchesLevel = _level == 'Semua' || comp.levelName == _level;
        bool matchesStatus = true;
        if (_status == 'Aktif') matchesStatus = comp.isActive;
        else if (_status == 'Tidak Aktif') matchesStatus = !comp.isActive;
        return matchesCategory && matchesLevel && matchesStatus;
      }).toList();

      _competitions.addAll(newItems);
      _cursor = res.nextCursor;
      _hasMore = res.nextCursor != null;

      // Update metadata list for UI
      if (refresh) {
        _categories = ['Semua', ..._competitions.map((e) => e.categoryName).toSet().toList()];
        _levels = ['Semua', ..._competitions.map((e) => e.levelName).toSet().toList()];
      }
      
    } catch (e) {
      debugPrint('Error fetching competitions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _competitions = [];
    _cursor = null;
    _hasMore = true;
    notifyListeners();
  }
}
