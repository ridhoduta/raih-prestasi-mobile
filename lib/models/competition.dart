class Competition {
  final String id;
  final String title;
  final String? description;
  final String? thumbnail;
  final DateTime startDate;
  final DateTime endDate;
  final String categoryName;
  final String levelName;
  final bool isActive;
  final List<CompetitionFormField> formFields;

  Competition({
    this.id = '',
    required this.title,
    this.description,
    this.thumbnail,
    DateTime? startDate,
    DateTime? endDate,
    this.categoryName = '',
    this.levelName = '',
    this.isActive = true,
    this.formFields = const [],
  }) : startDate = startDate ?? DateTime.now(),
       endDate = endDate ?? DateTime.now();

  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Tanpa Judul',
      description: json['description'],
      thumbnail: json['thumbnail'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      categoryName: json['category']?['name'] ?? '',
      levelName: json['level']?['name'] ?? '',
      isActive: json['isActive'] ?? true,
      formFields: json['CompetitionFormField'] != null
          ? (json['CompetitionFormField'] as List)
                .map((f) => CompetitionFormField.fromJson(f))
                .toList()
          : [],
    );
  }
}

class CompetitionFormField {
  final String id;
  final String label;
  final String fieldType;
  final bool isRequired;
  final dynamic options;
  final int order;

  CompetitionFormField({
    required this.id,
    required this.label,
    required this.fieldType,
    required this.isRequired,
    this.options,
    required this.order,
  });

  factory CompetitionFormField.fromJson(Map<String, dynamic> json) {
    return CompetitionFormField(
      id: json['id'],
      label: json['label'],
      fieldType: json['fieldType'],
      isRequired: json['isRequired'] ?? false,
      options: json['options'],
      order: json['order'] ?? 0,
    );
  }
}

class CompetitionRegistration {
  final String id;
  final String competitionId;
  final String studentId;
  final String status;
  final String? note;
  final DateTime createdAt;
  final Competition? competition;
  final List<RegistrationAnswerDetail>? answers;

  CompetitionRegistration({
    required this.id,
    required this.competitionId,
    required this.studentId,
    required this.status,
    this.note,
    required this.createdAt,
    this.competition,
    this.answers,
  });

  factory CompetitionRegistration.fromJson(Map<String, dynamic> json) {
    return CompetitionRegistration(
      id: json['id'] ?? '',
      competitionId: json['competitionId'] ?? json['competition']?['id'] ?? '',
      studentId: json['studentId'] ?? json['student']?['id'] ?? '',
      status: json['status'] ?? '',
      note: json['note'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      competition: json['competition'] != null
          ? Competition.fromJson(json['competition'])
          : null,
      answers: json['answers'] != null
          ? (json['answers'] as List)
                .map((a) => RegistrationAnswerDetail.fromJson(a))
                .toList()
          : null,
    );
  }
}

class RegistrationAnswerDetail {
  final String id;
  final String fieldLabel;
  final dynamic value;

  RegistrationAnswerDetail({
    required this.id,
    required this.fieldLabel,
    required this.value,
  });

  factory RegistrationAnswerDetail.fromJson(Map<String, dynamic> json) {
    return RegistrationAnswerDetail(
      id: json['id'] ?? '',
      fieldLabel: json['field']?['label'] ?? 'Unknown Field',
      value: json['value'],
    );
  }
}

class Registration {
  final String studentId;
  final List<RegistrationAnswer> answers;

  Registration({required this.studentId, required this.answers});

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}

class RegistrationAnswer {
  final String fieldId;
  final dynamic value;

  RegistrationAnswer({required this.fieldId, required this.value});

  Map<String, dynamic> toJson() {
    return {'fieldId': fieldId, 'value': value};
  }
}
