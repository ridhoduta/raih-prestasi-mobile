import 'academic_score.dart';
import 'achievement.dart';

class StudentAcademic {
  final String id;
  final String name;
  final String nisn;
  final String? kelas;
  final List<Achievement> achievements;
  final List<AcademicScore> academicScores;

  StudentAcademic({
    required this.id,
    required this.name,
    required this.nisn,
    this.kelas,
    required this.achievements,
    required this.academicScores,
  });

  factory StudentAcademic.fromJson(Map<String, dynamic> json) {
    return StudentAcademic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nisn: json['nisn'] ?? '',
      kelas: json['kelas'],
      achievements: (json['achievements'] as List? ?? [])
          .map((a) => Achievement.fromJson(a))
          .toList(),
      academicScores: (json['academicScores'] as List? ?? [])
          .map((s) => AcademicScore.fromJson(s))
          .toList(),
    );
  }
}
