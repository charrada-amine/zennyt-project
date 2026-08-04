import 'package:equatable/equatable.dart';

class MatchEntity extends Equatable {
  final String matchId;
  final String candidateId;
  final String jobOfferId;
  final String candidateName;
  final String jobTitle;
  final String companyName;
  final DateTime matchedAt;

  const MatchEntity({
    required this.matchId,
    required this.candidateId,
    required this.jobOfferId,
    required this.candidateName,
    required this.jobTitle,
    required this.companyName,
    required this.matchedAt,
  });

  @override
  List<Object?> get props => [
        matchId,
        candidateId,
        jobOfferId,
        candidateName,
        jobTitle,
        companyName,
        matchedAt,
      ];
}
