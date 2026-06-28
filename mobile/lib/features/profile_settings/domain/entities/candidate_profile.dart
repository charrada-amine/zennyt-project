import 'package:flutter/foundation.dart';

/// Domain entity mirroring the backend `Profile` schema
/// (see `contracts/identity.openapi.yaml`). Read-only model used to hydrate the
/// candidate profile UI; the presentation layer maps it onto its view state.
@immutable
class CandidateProfile {
  const CandidateProfile({
    this.currentPosition,
    this.lookingFor,
    this.workplaceType,
    this.jobType,
    this.targetJobLocation,
    this.yearsOfExperience,
    this.softSkillsScore,
    this.aboutMe,
    this.openInternationally = false,
    this.availabilityType,
    this.availabilityDate,
    this.resumeAiUrl,
    this.portfolioUrl,
    this.skills = const [],
    this.positions = const [],
    this.certifications = const [],
    this.education = const [],
  });

  final String? currentPosition;
  final String? lookingFor;
  final String? workplaceType; // wire enum
  final String? jobType; // wire enum
  final String? targetJobLocation;
  final int? yearsOfExperience;
  final int? softSkillsScore;
  final String? aboutMe;
  final bool openInternationally;
  final String? availabilityType; // wire enum
  final String? availabilityDate; // yyyy-MM-dd
  final String? resumeAiUrl;
  final String? portfolioUrl;
  final List<ProfileSkill> skills;
  final List<ProfilePosition> positions;
  final List<ProfileCertification> certifications;
  final List<ProfileEducation> education;

  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) from) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(from)
          .toList(growable: false);
    }

    return CandidateProfile(
      currentPosition: json['currentPosition'] as String?,
      lookingFor: json['lookingFor'] as String?,
      workplaceType: json['workplaceType'] as String?,
      jobType: json['jobType'] as String?,
      targetJobLocation: json['targetJobLocation'] as String?,
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt(),
      softSkillsScore: (json['softSkillsScore'] as num?)?.toInt(),
      aboutMe: json['aboutMe'] as String?,
      openInternationally: (json['openInternationally'] ?? false) as bool,
      availabilityType: json['availabilityType'] as String?,
      availabilityDate: json['availabilityDate'] as String?,
      resumeAiUrl: json['resumeAiUrl'] as String?,
      portfolioUrl: json['portfolioUrl'] as String?,
      skills: list('skills', ProfileSkill.fromJson),
      positions: list('positions', ProfilePosition.fromJson),
      certifications: list('certifications', ProfileCertification.fromJson),
      education: list('education', ProfileEducation.fromJson),
    );
  }
}

@immutable
class ProfileSkill {
  const ProfileSkill({
    required this.id,
    required this.name,
    this.type,
    this.level,
  });

  final String id;
  final String name;
  final String? type; // TECHNICAL | SOFT
  final int? level;

  factory ProfileSkill.fromJson(Map<String, dynamic> json) => ProfileSkill(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '') as String,
    type: json['type'] as String?,
    level: (json['level'] as num?)?.toInt(),
  );
}

@immutable
class ProfilePosition {
  const ProfilePosition({
    required this.id,
    required this.title,
    this.companyName,
    this.location,
    this.startDate,
    this.endDate,
    this.current = false,
  });

  final String id;
  final String title;
  final String? companyName;
  final String? location;
  final String? startDate; // yyyy-MM-dd
  final String? endDate; // yyyy-MM-dd
  final bool current;

  factory ProfilePosition.fromJson(Map<String, dynamic> json) =>
      ProfilePosition(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '') as String,
        companyName: json['companyName'] as String?,
        location: json['location'] as String?,
        startDate: json['startDate'] as String?,
        endDate: json['endDate'] as String?,
        current: (json['current'] ?? false) as bool,
      );
}

@immutable
class ProfileCertification {
  const ProfileCertification({
    required this.id,
    required this.title,
    this.issuer,
    this.completionDate,
  });

  final String id;
  final String title;
  final String? issuer;
  final String? completionDate; // yyyy-MM-dd

  factory ProfileCertification.fromJson(Map<String, dynamic> json) =>
      ProfileCertification(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '') as String,
        issuer: json['issuer'] as String?,
        completionDate: json['completionDate'] as String?,
      );
}

@immutable
class ProfileEducation {
  const ProfileEducation({
    required this.id,
    required this.degree,
    this.school,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String degree;
  final String? school;
  final String? startDate; // yyyy-MM-dd
  final String? endDate; // yyyy-MM-dd

  factory ProfileEducation.fromJson(Map<String, dynamic> json) =>
      ProfileEducation(
        id: (json['id'] ?? '').toString(),
        degree: (json['degree'] ?? '') as String,
        school: json['school'] as String?,
        startDate: json['startDate'] as String?,
        endDate: json['endDate'] as String?,
      );
}
