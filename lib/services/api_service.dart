import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../models/achievement.dart';
import '../models/competition.dart';
import '../models/submission.dart';
import '../models/news.dart';
import '../models/announcement.dart';
import '../models/academic_score.dart';
import '../models/auth_response.dart';
import '../models/api_response.dart';
import '../models/notification.dart';
import 'session_service.dart';

class ApiService {
  // Use persistent client for connection pooling.
  final http.Client client = http.Client();
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'https://raih-prestasi.vercel.app/api';

  // Simple in-memory cache for GET requests.
  final Map<String, dynamic> _cache = {};

  // --- Header Helpers ---

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth) {
      final token = await SessionService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- Auth APIs ---

  Future<AuthResponse> login(String nisn, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'nisn': nisn, 'password': password}),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(json.decode(response.body));
    } else {
      final message = json.decode(response.body)['message'] ?? 'Login gagal';
      throw Exception(message);
    }
  }

  Future<bool> changePassword(
    String studentId,
    String oldPassword,
    String newPassword,
  ) async {
    final response = await client.put(
      Uri.parse('$baseUrl/student/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'studentId': studentId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      String errorMessage = 'Gagal mengganti password';
      try {
        final body = json.decode(response.body);
        if (body is Map) {
          errorMessage = body['message'] ?? body['error'] ?? errorMessage;
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      throw Exception(errorMessage);
    }
  }

  // --- Generic Paginated GET with Cache & Compute ---

  Future<PaginatedResponse<T>> _getPaginatedData<T>(
    String path,
    Map<String, String> queryParams,
    T Function(Map<String, dynamic>) fromJson, {
    bool forceRefresh = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final cacheKey = uri.toString();

    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as PaginatedResponse<T>;
    }

    final headers = await _getHeaders();
    final response = await client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      // Decode JSON in a separate isolate if it's large.
      // json.decode is a standard function that can be safely used with compute.
      final Map<String, dynamic> jsonData = await compute(
        _decodeJson,
        response.body,
      );
      
      final paginatedResult = PaginatedResponse.fromJson(jsonData, fromJson);
      _cache[cacheKey] = paginatedResult;
      return paginatedResult;
    } else {
      throw Exception('Gagal mengambil data dari $path');
    }
  }

  // --- API Handlers ---

  Future<PaginatedResponse<Achievement>> getAchievements(
    String studentId, {
    int limit = 20,
    String? cursor,
    String? search,
    bool forceRefresh = false,
  }) async {
    return _getPaginatedData(
      '/student/achievement/$studentId',
      {
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null) 'search': search,
      },
      (json) => Achievement.fromJson(json),
      forceRefresh: forceRefresh,
    );
  }

  Future<PaginatedResponse<Competition>> getActiveCompetitions({
    int limit = 20,
    String? cursor,
    String? search,
    bool forceRefresh = false,
  }) async {
    return _getPaginatedData(
      '/guru/competitions',
      {
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null) 'search': search,
      },
      (json) => Competition.fromJson(json),
      forceRefresh: forceRefresh,
    );
  }

  Future<PaginatedResponse<CompetitionRegistration>> getStudentRegistrations(
    String studentId, {
    int limit = 20,
    String? cursor,
    String? search,
    bool forceRefresh = false,
  }) async {
    return _getPaginatedData(
      '/guru/registrations',
      {
        'studentId': studentId,
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null) 'search': search,
      },
      (json) => CompetitionRegistration.fromJson(json),
      forceRefresh: forceRefresh,
    );
  }

  Future<PaginatedResponse<IndependentSubmission>> getSubmissions(
    String studentId, {
    int limit = 20,
    String? cursor,
    String? search,
    bool forceRefresh = false,
  }) async {
    return _getPaginatedData(
      '/student/independent-submissions',
      {
        'studentId': studentId,
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null) 'search': search,
      },
      (json) => IndependentSubmission.fromJson(json),
      forceRefresh: forceRefresh,
    );
  }

  Future<PaginatedResponse<News>> getNews({
    int limit = 20,
    String? cursor,
    String? search,
    bool forceRefresh = false,
  }) async {
    return _getPaginatedData(
      '/admin/news',
      {
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null) 'search': search,
      },
      (json) => News.fromJson(json),
      forceRefresh: forceRefresh,
    );
  }

  Future<PaginatedResponse<Announcement>> getAnnouncements({
    int limit = 20,
    String? cursor,
    String? search,
    bool forceRefresh = false,
  }) async {
    return _getPaginatedData(
      '/guru/announcement',
      {
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null) 'search': search,
      },
      (json) => Announcement.fromJson(json),
      forceRefresh: forceRefresh,
    );
  }

  Future<List<AcademicScore>> getMyScores(String studentId, {bool forceRefresh = false}) async {
    final uri = Uri.parse('$baseUrl/student/academic-scores/me?studentId=$studentId');
    final cacheKey = uri.toString();
    
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<AcademicScore>;
    }

    final headers = await _getHeaders();
    final response = await client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      final result = data.map((json) => AcademicScore.fromJson(json)).toList();
      _cache[cacheKey] = result;
      return result;
    } else {
      throw Exception('Gagal mengambil nilai akademik');
    }
  }

  // --- Notification & FCM APIs ---

  Future<bool> registerFcmToken(String studentId, String token) async {
    try {
      final headers = await _getHeaders();
      final response = await client.post(
        Uri.parse('$baseUrl/student/fcm-token'),
        headers: headers,
        body: json.encode({
          'token': token,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) print('FCM token registered successfully');
        return true;
      } else {
        if (kDebugMode) print('Failed to register FCM token: ${response.body}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Error registering FCM token: $e');
      return false;
    }
  }

  Future<PaginatedResponse<NotificationModel>> getNotifications(
    String studentId, {
    int limit = 20,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    return _getPaginatedData(
      '/student/notifications',
      {
        'studentId': studentId,
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
      },
      (json) => NotificationModel.fromJson(json),
      forceRefresh: forceRefresh,
    );
  }

  Future<bool> markNotificationsAsRead(String studentId, {String? notificationId}) async {
    try {
      final headers = await _getHeaders();
      final response = await client.patch(
        Uri.parse('$baseUrl/student/notifications'),
        headers: headers,
        body: json.encode({
          'studentId': studentId,
          'id': notificationId ?? 'all',
        }),
      );

      if (response.statusCode == 200) {
        _invalidateCache('/student/notifications');
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read: $e');
      return false;
    }
  }

  // --- Mutation APIs (Auto Invalidate Cache) ---

  Future<bool> postAchievement(Achievement achievement) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('$baseUrl/student/achievement'),
      headers: headers,
      body: json.encode(achievement.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      _invalidateCache('/student/achievement');
      return true;
    }
    return false;
  }

  Future<bool> postSubmission(IndependentSubmission submission) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('$baseUrl/student/independent-submissions'),
      headers: headers,
      body: json.encode(submission.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      _invalidateCache('/student/independent-submissions');
      return true;
    }
    return false;
  }

  Future<bool> registerCompetition(String competitionId, Registration registration) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('$baseUrl/student/competitions/$competitionId/register'),
      headers: headers,
      body: json.encode(registration.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      _invalidateCache('/guru/registrations');
      return true;
    }
    return false;
  }

  Future<bool> deleteSubmission(String id) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse('$baseUrl/student/independent-submissions/$id'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      _invalidateCache('/student/independent-submissions');
      return true;
    }
    return false;
  }

  void _invalidateCache(String pathPrefix) {
    _cache.removeWhere((key, value) => key.contains(pathPrefix));
  }

  Future<String> uploadFile(String filePath) async {
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['url']['publicUrl'];
      } else {
        throw Exception(data['message'] ?? 'Gagal mengunggah file');
      }
    } else {
      throw Exception('Gagal mengunggah file: ${response.statusCode}');
    }
  }

  void clearCache() {
    _cache.clear();
  }
}

// Global parsing function for compute - only handles JSON decoding to remain serializable.
Map<String, dynamic> _decodeJson(String body) {
  return json.decode(body) as Map<String, dynamic>;
}
