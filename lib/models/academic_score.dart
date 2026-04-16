class AcademicScore {
  final String id;
  final String subject;
  final double score;
  final String semester;
  final String academicYear;

  AcademicScore({
    required this.id,
    required this.subject,
    required this.score,
    required this.semester,
    required this.academicYear,
  });

  factory AcademicScore.fromJson(Map<String, dynamic> json) {
    return AcademicScore(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      score: (json['score'] as num? ?? 0).toDouble(),
      semester: json['semester'] ?? '',
      academicYear: json['academicYear'] ?? '',
    );
  }
}

