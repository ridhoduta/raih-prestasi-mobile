class IndependentSubmission {
  final String? id;
  final String studentId;
  final String title;
  final String? description;
  final String documentUrl;
  final String? status;
  final String? rejectionNote;
  final String? recommendationLetter;
  final DateTime? createdAt;

  IndependentSubmission({
    this.id,
    required this.studentId,
    required this.title,
    this.description,
    required this.documentUrl,
    this.status,
    this.rejectionNote,
    this.recommendationLetter,
    this.createdAt,
  });

  factory IndependentSubmission.fromJson(Map<String, dynamic> json) {
    return IndependentSubmission(
      id: json['id'],
      studentId: json['studentId'],
      title: json['title'],
      description: json['description'],
      documentUrl: json['documentUrl'],
      status: json['status'],
      rejectionNote: json['rejectionNote'],
      recommendationLetter: json['recommendationLetter'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'title': title,
      'description': description,
      'documentUrl': documentUrl,
    };
  }
}
