/// Request body for `POST /profiles` and `PUT /profiles/me` (`ProfileInput`).
///
/// Enum fields must already be wire values (e.g. `HYBRID`, `FULL_TIME`,
/// `IMMEDIATELY`). Empty/null fields are omitted so a partial update never wipes
/// existing data.
class ProfileInput {
  const ProfileInput({
    this.currentPosition,
    this.lookingFor,
    this.workplaceType,
    this.jobType,
    this.targetJobLocation,
    this.yearsOfExperience,
    this.softSkillsScore,
    this.aboutMe,
    this.openInternationally,
    this.availabilityType,
    this.availabilityDate,
    this.resumeAiUrl,
    this.portfolioUrl,
  });

  final String? currentPosition;
  final String? lookingFor;
  final String? workplaceType;
  final String? jobType;
  final String? targetJobLocation;
  final int? yearsOfExperience;
  final int? softSkillsScore;
  final String? aboutMe;
  final bool? openInternationally;
  final String? availabilityType;
  final String? availabilityDate; // yyyy-MM-dd
  final String? resumeAiUrl;
  final String? portfolioUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    void putString(String key, String? value) {
      if (value != null && value.isNotEmpty) map[key] = value;
    }

    putString('currentPosition', currentPosition);
    putString('lookingFor', lookingFor);
    putString('workplaceType', workplaceType);
    putString('jobType', jobType);
    putString('targetJobLocation', targetJobLocation);
    if (yearsOfExperience != null) map['yearsOfExperience'] = yearsOfExperience;
    if (softSkillsScore != null) map['softSkillsScore'] = softSkillsScore;
    putString('aboutMe', aboutMe);
    if (openInternationally != null) {
      map['openInternationally'] = openInternationally;
    }
    putString('availabilityType', availabilityType);
    putString('availabilityDate', availabilityDate);
    putString('resumeAiUrl', resumeAiUrl);
    putString('portfolioUrl', portfolioUrl);

    return map;
  }
}
