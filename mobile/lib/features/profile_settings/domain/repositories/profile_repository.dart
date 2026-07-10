import '../../data/dtos/profile_input.dart';
import '../../data/dtos/sub_resource_inputs.dart';
import '../entities/candidate_profile.dart';

/// Access to the candidate's professional profile (identity `/profiles` API).
abstract class ProfileRepository {
  /// `GET /profiles/me`. Returns `null` when the user has not created a
  /// professional profile yet (backend responds 404).
  Future<CandidateProfile?> getMyProfile();

  /// Creates (`POST /profiles`) or updates (`PUT /profiles/me`) the profile and
  /// returns the persisted result. Pass [exists] = true to update.
  Future<CandidateProfile> saveProfile(
    ProfileInput input, {
    required bool exists,
  });

  // ── Skills ──────────────────────────────────────────────────────────────

  Future<ProfileSkill> addSkill(SkillInput input);
  Future<ProfileSkill> updateSkill(String id, SkillInput input);
  Future<void> deleteSkill(String id);

  // ── Positions ───────────────────────────────────────────────────────────

  Future<ProfilePosition> addPosition(PositionInput input);
  Future<ProfilePosition> updatePosition(String id, PositionInput input);
  Future<void> deletePosition(String id);

  // ── Certifications ──────────────────────────────────────────────────────

  Future<ProfileCertification> addCertification(CertificationInput input);
  Future<ProfileCertification> updateCertification(
    String id,
    CertificationInput input,
  );
  Future<void> deleteCertification(String id);

  // ── Education ───────────────────────────────────────────────────────────

  Future<ProfileEducation> addEducation(EducationInput input);
  Future<ProfileEducation> updateEducation(String id, EducationInput input);
  Future<void> deleteEducation(String id);
  
  /// Uploads a CV file
  Future<void> uploadCv(String filePath);
}
