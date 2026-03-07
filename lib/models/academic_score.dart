class AcademicScore {
  final String id;
  final String subject;
  final double score;
  final String semester;
  final int year;

  AcademicScore({
    required this.id,
    required this.subject,
    required this.score,
    required this.semester,
    required this.year,
  });

  factory AcademicScore.fromJson(Map<String, dynamic> json) {
    return AcademicScore(
      id: json['id'],
      subject: json['subject'],
      score: (json['score'] as num).toDouble(),
      semester: json['semester'],
      year: json['year'],
    );
  }
}
