class RecruiterProfile {
  const RecruiterProfile({
    required this.jobTitle,
    required this.companyName,
    required this.companySize,
    required this.fieldOfWork,
    required this.companyLocation,
    required this.companyRegistrationNumber,
    this.companyLogoUrl,
    this.aboutMe,
    this.about,
    this.mission,
    this.vision,
    this.missionVision,
    this.keyDifferentiators,
    this.cultureWorkEnvironment,
    this.whyJoinUs,
  });

  final String jobTitle;
  final String companyName;
  final String companySize;
  final String fieldOfWork;
  final String companyLocation;
  final String companyRegistrationNumber;
  final String? companyLogoUrl;
  final String? aboutMe;
  final String? about;
  final String? mission;
  final String? vision;
  final String? missionVision;
  final String? keyDifferentiators;
  final String? cultureWorkEnvironment;
  final String? whyJoinUs;

  factory RecruiterProfile.fromJson(Map<String, dynamic> json) {
    return RecruiterProfile(
      jobTitle: json['jobTitle'] as String,
      companyName: json['companyName'] as String,
      companySize: json['companySize'] as String,
      fieldOfWork: json['fieldOfWork'] as String,
      companyLocation: json['companyLocation'] as String,
      companyRegistrationNumber: json['companyRegistrationNumber'] as String,
      companyLogoUrl: json['companyLogoUrl'] as String?,
      aboutMe: json['aboutMe'] as String?,
      about: json['about'] as String?,
      mission: json['mission'] as String?,
      vision: json['vision'] as String?,
      missionVision: json['missionVision'] as String?,
      keyDifferentiators: json['keyDifferentiators'] as String?,
      cultureWorkEnvironment: json['cultureWorkEnvironment'] as String?,
      whyJoinUs: json['whyJoinUs'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobTitle': jobTitle,
      'companyName': companyName,
      'companySize': companySize,
      'fieldOfWork': fieldOfWork,
      'companyLocation': companyLocation,
      'companyRegistrationNumber': companyRegistrationNumber,
      if (companyLogoUrl != null) 'companyLogoUrl': companyLogoUrl,
      if (aboutMe != null) 'aboutMe': aboutMe,
      if (about != null) 'about': about,
      if (mission != null) 'mission': mission,
      if (vision != null) 'vision': vision,
      if (keyDifferentiators != null) 'keyDifferentiators': keyDifferentiators,
      if (cultureWorkEnvironment != null) 'cultureWorkEnvironment': cultureWorkEnvironment,
      if (whyJoinUs != null) 'whyJoinUs': whyJoinUs,
    };
  }

  RecruiterProfile copyWith({
    String? jobTitle,
    String? companyName,
    String? companySize,
    String? fieldOfWork,
    String? companyLocation,
    String? companyRegistrationNumber,
    String? companyLogoUrl,
    String? aboutMe,
    String? about,
    String? mission,
    String? vision,
    String? keyDifferentiators,
    String? cultureWorkEnvironment,
    String? whyJoinUs,
  }) {
    return RecruiterProfile(
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      companySize: companySize ?? this.companySize,
      fieldOfWork: fieldOfWork ?? this.fieldOfWork,
      companyLocation: companyLocation ?? this.companyLocation,
      companyRegistrationNumber: companyRegistrationNumber ?? this.companyRegistrationNumber,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      aboutMe: aboutMe ?? this.aboutMe,
      about: about ?? this.about,
      mission: mission ?? this.mission,
      vision: vision ?? this.vision,
      missionVision: missionVision ?? this.missionVision,
      keyDifferentiators: keyDifferentiators ?? this.keyDifferentiators,
      cultureWorkEnvironment: cultureWorkEnvironment ?? this.cultureWorkEnvironment,
      whyJoinUs: whyJoinUs ?? this.whyJoinUs,
    );
  }
}
