class AuthResponse {
  final String message;
  final StudentUser user;
  final String? token;

  AuthResponse({required this.message, required this.user, this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final userJson = json['user'] as Map<String, dynamic>;
    
    // Ensure the token is included in the user object for session storage
    if (token != null && !userJson.containsKey('token')) {
      userJson['token'] = token;
    }

    return AuthResponse(
      message: json['message'] ?? '',
      user: StudentUser.fromJson(userJson),
      token: token,
    );
  }
}

class StudentUser {
  final String id;
  final String name;
  final String nisn;
  final String? kelas;
  final int? angkatan;
  final String? token;

  StudentUser({
    required this.id,
    required this.name,
    required this.nisn,
    this.kelas,
    this.angkatan,
    this.token,
  });

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nisn: json['nisn'] ?? '',
      kelas: json['kelas'],
      angkatan: json['angkatan'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nisn': nisn,
      'kelas': kelas,
      'angkatan': angkatan,
      'token': token,
    };
  }
}
