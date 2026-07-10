class CvParsedData {
  final bool? isValidCv;
  final String? currentPosition;
  final String? aboutMe;
  final int? yearsOfExperience;
  final List<CvParsedSkill> skills;
  final List<CvParsedPosition> positions;
  final List<CvParsedEducation> education;
  final List<CvParsedCertification> certifications;

  CvParsedData({
    this.isValidCv,
    this.currentPosition,
    this.aboutMe,
    this.yearsOfExperience,
    this.skills = const [],
    this.positions = const [],
    this.education = const [],
    this.certifications = const [],
  });

  CvParsedData copyWith({
    bool? isValidCv,
    String? currentPosition,
    String? aboutMe,
    int? yearsOfExperience,
    List<CvParsedSkill>? skills,
    List<CvParsedPosition>? positions,
    List<CvParsedEducation>? education,
    List<CvParsedCertification>? certifications,
  }) {
    return CvParsedData(
      isValidCv: isValidCv ?? this.isValidCv,
      currentPosition: currentPosition ?? this.currentPosition,
      aboutMe: aboutMe ?? this.aboutMe,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      skills: skills ?? this.skills,
      positions: positions ?? this.positions,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
    );
  }

  factory CvParsedData.fromJson(Map<String, dynamic> json) {
    return CvParsedData(
      isValidCv: json['isValidCv'] as bool?,
      currentPosition: json['currentPosition'] as String?,
      aboutMe: json['aboutMe'] as String?,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => CvParsedSkill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      positions: (json['positions'] as List<dynamic>?)
              ?.map((e) => CvParsedPosition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => CvParsedEducation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((e) => CvParsedCertification.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CvParsedSkill {
  final String name;
  final String type;
  final int? level;

  CvParsedSkill({required this.name, required this.type, this.level});

  CvParsedSkill copyWith({
    String? name,
    String? type,
    int? level,
  }) {
    return CvParsedSkill(
      name: name ?? this.name,
      type: type ?? this.type,
      level: level ?? this.level,
    );
  }

  factory CvParsedSkill.fromJson(Map<String, dynamic> json) {
    return CvParsedSkill(
      name: json['name'] as String,
      type: json['type'] as String,
      level: json['level'] as int?,
    );
  }
}

class CvParsedPosition {
  final String title;
  final String? companyName;
  final String? location;
  final String? description;
  final String? startDate;
  final String? endDate;
  final bool current;

  CvParsedPosition({
    required this.title,
    this.companyName,
    this.location,
    this.description,
    this.startDate,
    this.endDate,
    this.current = false,
  });

  CvParsedPosition copyWith({
    String? title,
    String? companyName,
    String? location,
    String? description,
    String? startDate,
    String? endDate,
    bool? current,
  }) {
    return CvParsedPosition(
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      current: current ?? this.current,
    );
  }

  factory CvParsedPosition.fromJson(Map<String, dynamic> json) {
    return CvParsedPosition(
      title: json['title'] as String,
      companyName: json['companyName'] as String?,
      location: json['location'] as String?,
      description: json['description'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      current: json['current'] as bool? ?? false,
    );
  }
}

class CvParsedEducation {
  final String degree;
  final String? school;
  final String? fieldOfStudy;
  final String? description;
  final String? startDate;
  final String? endDate;

  CvParsedEducation({
    required this.degree,
    this.school,
    this.fieldOfStudy,
    this.description,
    this.startDate,
    this.endDate,
  });

  CvParsedEducation copyWith({
    String? degree,
    String? school,
    String? fieldOfStudy,
    String? description,
    String? startDate,
    String? endDate,
  }) {
    return CvParsedEducation(
      degree: degree ?? this.degree,
      school: school ?? this.school,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  factory CvParsedEducation.fromJson(Map<String, dynamic> json) {
    return CvParsedEducation(
      degree: json['degree'] as String,
      school: json['school'] as String?,
      fieldOfStudy: json['fieldOfStudy'] as String?,
      description: json['description'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
    );
  }
}

class CvParsedCertification {
  final String title;
  final String? issuer;
  final String? completionDate;
  final String? credentialId;
  final String? credentialUrl;

  CvParsedCertification({
    required this.title,
    this.issuer,
    this.completionDate,
    this.credentialId,
    this.credentialUrl,
  });

  CvParsedCertification copyWith({
    String? title,
    String? issuer,
    String? completionDate,
    String? credentialId,
    String? credentialUrl,
  }) {
    return CvParsedCertification(
      title: title ?? this.title,
      issuer: issuer ?? this.issuer,
      completionDate: completionDate ?? this.completionDate,
      credentialId: credentialId ?? this.credentialId,
      credentialUrl: credentialUrl ?? this.credentialUrl,
    );
  }

  factory CvParsedCertification.fromJson(Map<String, dynamic> json) {
    return CvParsedCertification(
      title: json['title'] as String,
      issuer: json['issuer'] as String?,
      completionDate: json['completionDate'] as String?,
      credentialId: json['credentialId'] as String?,
      credentialUrl: json['credentialUrl'] as String?,
    );
  }
}
