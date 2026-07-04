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
  });

  final String jobTitle;
  final String companyName;
  final String companySize;
  final String fieldOfWork;
  final String companyLocation;
  final String companyRegistrationNumber;
  final String? companyLogoUrl;
  final String? aboutMe;

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
    );
  }

}
