import 'dart:convert';
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

class ApiService {
  // Use local IP for WiFi access.
  // static const String baseUrl = 'http://192.168.100.77:3000/api';
  static const String baseUrl = 'https://raih-prestasi.vercel.app/api';

  // --- Auth APIs ---

  Future<AuthResponse> login(String nisn, String password) async {
    final response = await http.post(
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

  // --- Achievement APIs ---

  Future<List<Achievement>> getAchievements(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/achievement/$studentId'),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data']['data'] ?? [];
      return data.map((json) => Achievement.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil data prestasi');
    }
  }

  Future<bool> postAchievement(Achievement achievement) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/achievement'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(achievement.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // --- Competition APIs ---

  Future<List<Competition>> getActiveCompetitions() async {
    final response = await http.get(Uri.parse('$baseUrl/guru/competitions'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data.map((json) => Competition.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil daftar kompetisi');
    }
  }

  Future<Competition> getCompetitionDetail(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/guru/competitions/$id'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      return Competition.fromJson(data);
    } else {
      throw Exception('Gagal mengambil detail kompetisi');
    }
  }

  Future<bool> registerCompetition(
    String competitionId,
    Registration registration,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/competitions/$competitionId/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(registration.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<CompetitionRegistration>> getStudentRegistrations(
    String studentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/guru/registrations?studentId=$studentId'),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data
          .map((json) => CompetitionRegistration.fromJson(json))
          .toList();
    } else {
      throw Exception('Gagal mengambil data pendaftaran');
    }
  }

  // --- Independent Submission APIs ---

  Future<List<IndependentSubmission>> getSubmissions(String studentId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/student/independent-submissions?studentId=$studentId',
      ),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data.map((json) => IndependentSubmission.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil data pengajuan');
    }
  }

  Future<bool> postSubmission(IndependentSubmission submission) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/independent-submissions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(submission.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // --- News & Announcements ---

  Future<List<News>> getNews() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/news'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data.map((json) => News.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil berita');
    }
  }

  Future<List<Announcement>> getAnnouncements() async {
    final response = await http.get(Uri.parse('$baseUrl/guru/announcement'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data.map((json) => Announcement.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil pengumuman');
    }
  }

  // --- Academic Scores ---

  Future<List<AcademicScore>> getMyScores(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/academic-scores/me?studentId=$studentId'),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data.map((json) => AcademicScore.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil nilai akademik');
    }
  }

  Future<bool> deleteSubmission(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/student/independent-submissions/$id'),
    );
    return response.statusCode == 200;
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
}
