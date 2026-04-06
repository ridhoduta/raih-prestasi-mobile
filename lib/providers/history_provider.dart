import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/submission.dart';
import '../models/competition.dart';
import '../services/api_service.dart';

class HistoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Achievement State
  List<Achievement> _achievements = [];
  String? _achievementCursor;
  bool _isLoadingAchievements = false;
  bool _hasMoreAchievements = true;

  List<Achievement> get achievements => _achievements;
  bool get isLoadingAchievements => _isLoadingAchievements;
  bool get hasMoreAchievements => _hasMoreAchievements;

  // Submission State
  List<IndependentSubmission> _submissions = [];
  String? _submissionCursor;
  bool _isLoadingSubmissions = false;
  bool _hasMoreSubmissions = true;

  List<IndependentSubmission> get submissions => _submissions;
  bool get isLoadingSubmissions => _isLoadingSubmissions;
  bool get hasMoreSubmissions => _hasMoreSubmissions;

  // Registration State
  List<CompetitionRegistration> _registrations = [];
  String? _registrationCursor;
  bool _isLoadingRegistrations = false;
  bool _hasMoreRegistrations = true;

  List<CompetitionRegistration> get registrations => _registrations;
  bool get isLoadingRegistrations => _isLoadingRegistrations;
  bool get hasMoreRegistrations => _hasMoreRegistrations;

  // --- Fetchers ---

  Future<void> fetchAchievements({bool refresh = false, String? studentId}) async {
    if (studentId == null) return;
    if (_isLoadingAchievements || (!refresh && !_hasMoreAchievements)) return;

    _isLoadingAchievements = true;
    if (refresh) {
      _achievementCursor = null;
      _hasMoreAchievements = true;
    }
    notifyListeners();

    try {
      final res = await _apiService.getAchievements(
        studentId,
        cursor: _achievementCursor,
        forceRefresh: refresh,
      );
      if (refresh) _achievements = [];
      _achievements.addAll(res.data);
      _achievementCursor = res.nextCursor;
      _hasMoreAchievements = res.nextCursor != null;
    } catch (e) {
      debugPrint('Error fetching achievements: $e');
    } finally {
      _isLoadingAchievements = false;
      notifyListeners();
    }
  }

  Future<void> fetchSubmissions({bool refresh = false, String? studentId}) async {
    if (studentId == null) return;
    if (_isLoadingSubmissions || (!refresh && !_hasMoreSubmissions)) return;

    _isLoadingSubmissions = true;
    if (refresh) {
      _submissionCursor = null;
      _hasMoreSubmissions = true;
    }
    notifyListeners();

    try {
      final res = await _apiService.getSubmissions(
        studentId,
        cursor: _submissionCursor,
        forceRefresh: refresh,
      );
      if (refresh) _submissions = [];
      _submissions.addAll(res.data);
      _submissionCursor = res.nextCursor;
      _hasMoreSubmissions = res.nextCursor != null;
    } catch (e) {
      debugPrint('Error fetching submissions: $e');
    } finally {
      _isLoadingSubmissions = false;
      notifyListeners();
    }
  }

  Future<void> fetchRegistrations({bool refresh = false, String? studentId}) async {
    if (studentId == null) return;
    if (_isLoadingRegistrations || (!refresh && !_hasMoreRegistrations)) return;

    _isLoadingRegistrations = true;
    if (refresh) {
      _registrationCursor = null;
      _hasMoreRegistrations = true;
    }
    notifyListeners();

    try {
      final res = await _apiService.getStudentRegistrations(
        studentId,
        cursor: _registrationCursor,
        forceRefresh: refresh,
      );
      if (refresh) _registrations = [];
      _registrations.addAll(res.data);
      _registrationCursor = res.nextCursor;
      _hasMoreRegistrations = res.nextCursor != null;
    } catch (e) {
      debugPrint('Error fetching registrations: $e');
    } finally {
      _isLoadingRegistrations = false;
      notifyListeners();
    }
  }

  void clearAll() {
    _achievements = [];
    _submissions = [];
    _registrations = [];
    _achievementCursor = null;
    _submissionCursor = null;
    _registrationCursor = null;
    _hasMoreAchievements = true;
    _hasMoreSubmissions = true;
    _hasMoreRegistrations = true;
    notifyListeners();
  }
}
