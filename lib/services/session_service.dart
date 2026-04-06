import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';

class SessionService {
  static const String _sessionKey = 'user_session';

  // Save user session
  static Future<bool> saveUser(StudentUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    return await prefs.setString(_sessionKey, userJson);
  }

  // Get user session
  static Future<StudentUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_sessionKey);
    if (userJson != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        return StudentUser.fromJson(userMap);
      } catch (e) {
        // Handle potential parsing errors if the format changed
        return null;
      }
    }
    return null;
  }

  // Get token directly
  static Future<String?> getToken() async {
    final user = await getUser();
    return user?.token;
  }

  // Clear user session (for Logout)
  static Future<bool> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_sessionKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_sessionKey);
  }
}
