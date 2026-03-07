class AuthResponse {
  final String message;
  final StudentUser user;

  AuthResponse({required this.message, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'],
      user: StudentUser.fromJson(json['user']),
    );
  }
}

class StudentUser {
  final String id;
  final String name;
  final String nisn;
  final String? kelas;
  final int? angkatan;

  StudentUser({
    required this.id,
    required this.name,
    required this.nisn,
    this.kelas,
    this.angkatan,
  });

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id'],
      name: json['name'],
      nisn: json['nisn'],
      kelas: json['kelas'],
      angkatan: json['angkatan'],
    );
  }
}
