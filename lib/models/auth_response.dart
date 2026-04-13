class AuthResponse {
  final String message;
  final StudentUser user;
  final String? token;

  AuthResponse({required this.message, required this.user, this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    // Create a mutable copy of the user map to avoid immutability issues
    final userMap = Map<String, dynamic>.from(json['user'] ?? {});
    
    // Ensure the token is included in the user object for session storage
    if (token != null) {
      userMap['token'] = token;
    }

    return AuthResponse(
      message: json['message'] ?? '',
      user: StudentUser.fromJson(userMap),
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
  final String? email;
  final String? role;
  final String? token;

  StudentUser({
    required this.id,
    required this.name,
    required this.nisn,
    this.kelas,
    this.angkatan,
    this.email,
    this.role,
    this.token,
  });

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nisn: json['nisn'] ?? '',
      kelas: json['kelas'],
      angkatan: json['angkatan'],
      email: json['email'],
      role: json['role'],
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
      'email': email,
      'role': role,
      'token': token,
    };
  }
}
