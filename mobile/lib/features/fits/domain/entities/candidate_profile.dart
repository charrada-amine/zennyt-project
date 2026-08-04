import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/app_user.dart';

class CandidateProfile extends Equatable {
  final AppUser user;
  final String targetRole;
  final String seniority;
  final int fitScore;
  final String location;
  final String decisionMaking;
  final String cognitiveFlexibility;
  final String emotionalRegulation;
  final Map<String, int> hardSkills;
  final List<String> contractTypes;
  final bool isImmediate;

  const CandidateProfile({
    required this.user,
    required this.targetRole,
    required this.seniority,
    required this.fitScore,
    required this.location,
    required this.decisionMaking,
    required this.cognitiveFlexibility,
    required this.emotionalRegulation,
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