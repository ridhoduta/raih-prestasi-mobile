class Achievement {
  final String id;
  final String studentId;
  final String competitionName;
  final String result;
  final String? certificate;
  final String status;
  final String? verifiedBy;
  final DateTime createdAt;

  Achievement({
    required this.id,
    required this.studentId,
    required this.competitionName,
    required this.result,
    this.certificate,
    required this.status,
    this.verifiedBy,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      studentId: json['studentId'],
      competitionName: json['competitionName'],
      result: json['result'],
      certificate: json['certificate'],
      status: json['status'],
      verifiedBy: json['verifiedBy'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'competitionName': competitionName,
      'result': result,
      'certificate': certificate,
    };
  }
}
