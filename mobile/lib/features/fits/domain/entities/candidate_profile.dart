import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/app_user.dart';

class CandidateProfile extends Equatable {
  final AppUser user;
  final String targetRole;
  final String seniority;
  final int fitScore;
  final String location;

  /// F10 (FITSCORE_REMEDIATION.md §3 index F10) — the backend's
  /// `CandidateFeedItem` only exposes one aggregate `softSkillsScore`; there is
  /// no per-module breakdown (decision-making, cognitive flexibility, emotional
  /// regulation) yet. This used to be rendered three times under three
  /// different module names from that single value, asserting a granularity
  /// to the recruiter that doesn't exist. One honest qualitative value instead.
  final String softSkillsLevel;

  /// Real `hardSkillScore` (contract-backed), one entry — not three fabricated
  /// module scores. Empty when the candidate hasn't been hard-skills tested
  /// for this offer yet (`hardSkillScore: null`).
  final Map<String, int> hardSkills;
  final List<String> contractTypes;
  final bool isImmediate;

  const CandidateProfile({
    required this.user,
    required this.targetRole,
    required this.seniority,
    required this.fitScore,
    required this.location,
    required this.softSkillsLevel,
    required this.hardSkills,
    required this.contractTypes,
    required this.isImmediate,
  });

  String get id => user.id;
  String get name => user.fullName;
  String get avatarUrl =>
      user.profileImageUrl ?? 'https://i.pravatar.cc/300?u=${user.id}';

  @override
  List<Object?> get props => [user, targetRole, seniority, fitScore, location];
}