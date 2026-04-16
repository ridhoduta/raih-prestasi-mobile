import 'package:flutter/foundation.dart';
import '../models/student_academic.dart';
import '../services/api_service.dart';

class AcademicProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<StudentAcademic> _students = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _academicYear = _getCurrentAcademicYear();
  String _semester = 'GANJIL';
  String _searchQuery = '';

  List<StudentAcademic> get students => _students;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get academicYear => _academicYear;
  String get semester => _semester;
  String get searchQuery => _searchQuery;

  AcademicProvider() {
    fetchAcademicData();
  }

  static String _getCurrentAcademicYear() {
    final now = DateTime.now();
    int startYear = now.month < 7 ? now.year - 1 : now.year;
    return '$startYear/${startYear + 1}';
  }

  void setFilter(String academicYear, String semester) {
    _academicYear = academicYear;
    _semester = semester;
    fetchAcademicData(forceRefresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchAcademicData(forceRefresh: true);
  }

  Future<void> fetchAcademicData({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _apiService.getAcademicData(
        search: _searchQuery,
        academicYear: _academicYear,
        semester: _semester,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchAcademicData(forceRefresh: true);
  }
}
