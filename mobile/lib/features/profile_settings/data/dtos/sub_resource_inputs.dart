/// Request body for `POST /profiles/me/skills` and `PUT /profiles/me/skills/{id}`.
class SkillInput {
  const SkillInput({
    required this.name,
    required this.type,
    this.level,
  });

  final String name;
  final String type; // TECHNICAL | SOFT
  final int? level;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'type': type,
    };
    if (level != null) map['level'] = level;
    return map;
  }
}

/// Request body for `POST /profiles/me/positions` and `PUT /profiles/me/positions/{id}`.
class PositionInput {
  const PositionInput({
    required this.title,
    this.companyName,
    this.location,
    this.description,
    this.startDate,
    this.endDate,
    this.current = false,
  });

  final String title;
  final String? companyName;
  final String? location;
  final String? description;
  final String? startDate; // yyyy-MM-dd
  final String? endDate; // yyyy-MM-dd
  final bool current;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'title': title, 'current': current};

    void putString(String key, String? value) {
      if (value != null && value.isNotEmpty) map[key] = value;
    }

    putString('companyName', companyName);
    putString('location', location);
    putString('description', description);
    putString('startDate', startDate);
    putString('endDate', endDate);
    return map;
  }
}

/// Request body for `POST /profiles/me/certifications` and
/// `PUT /profiles/me/certifications/{id}`.
class CertificationInput {
  const CertificationInput({
    required this.title,
    this.issuer,
    this.completionDate,
    this.credentialId,
    this.credentialUrl,
  });

  final String title;
  final String? issuer;
  final String? completionDate; // yyyy-MM-dd
  final String? credentialId;
  final String? credentialUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'title': title};

    void putString(String key, String? value) {
      if (value != null && value.isNotEmpty) map[key] = value;
    }

    putString('issuer', issuer);
    putString('completionDate', completionDate);
    putString('credentialId', credentialId);
    putString('credentialUrl', credentialUrl);
    return map;
  }
}

/// Request body for `POST /profiles/me/education` and
/// `PUT /profiles/me/education/{id}`.
class EducationInput {
  const EducationInput({
    required this.degree,
    this.school,
    this.fieldOfStudy,
    this.description,
    this.startDate,
    this.endDate,
  });

  final String degree;
  final String? school;
  final String? fieldOfStudy;
  final String? description;
  final String? startDate; // yyyy-MM-dd
  final String? endDate; // yyyy-MM-dd

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'degree': degree};

    void putString(String key, String? value) {
      if (value != null && value.isNotEmpty) map[key] = value;
    }

    putString('school', school);
    putString('fieldOfStudy', fieldOfStudy);
    putString('description', description);
    putString('startDate', startDate);
    putString('endDate', endDate);
    return map;
  }
}
