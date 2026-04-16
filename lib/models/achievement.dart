class Achievement {
  final String id;
  final String? studentId;
  final String competitionName;
  final String result;
  final String? certificate;
  final String? status;
  final String? verifiedBy;
  final DateTime? createdAt;
  final int? points;

  Achievement({
    required this.id,
    this.studentId,
    required this.competitionName,
    required this.result,
    this.certificate,
    this.status,
    this.verifiedBy,
    this.createdAt,
    this.points,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      studentId: json['studentId'],
      competitionName: json['competitionName'] ?? '',
      result: json['result'] ?? '',
      certificate: json['certificate'],
      status: json['status'],
      verifiedBy: json['verifiedBy'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      points: json['points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (studentId != null) 'studentId': studentId,
      'competitionName': competitionName,
      'result': result,
      'certificate': certificate,
      if (points != null) 'points': points,
    };
  }
}
