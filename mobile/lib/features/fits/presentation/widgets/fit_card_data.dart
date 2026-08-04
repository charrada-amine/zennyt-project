import '../../../jobs/domain/entities/job.dart';
import '../../domain/entities/candidate_profile.dart';


enum FitCardType { candidate, jobOffer }

class FitCardStat {
  final String label;
  final String value;
  const FitCardStat(this.label, this.value);
}

class FitCardData {
  final String id;
  final FitCardType type;
  final String avatarUrl;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final String primaryValue;
  final String section1Title;
  final List<FitCardStat> section1Stats;
  final String section2Title;
  final List<FitCardStat> section2Stats;
  final List<String> tags;
  final String? badgeText;

  final dynamic raw;

  const FitCardData({
    required this.id,
    required this.type,
    required this.avatarUrl,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryValue,
    required this.section1Title,
    required this.section1Stats,
    required this.section2Title,
    required this.section2Stats,
    required this.tags,
    required this.raw,
    this.badgeText,
  });

  factory FitCardData.fromCandidate(CandidateProfile c) => FitCardData(
        id: c.id,
        type: FitCardType.candidate,
        raw: c,
        avatarUrl: c.avatarUrl,
        title: c.name,
        subtitle: c.location,
        primaryLabel: 'Target role',
        primaryValue: '${c.targetRole} | ${c.seniority}',
        section1Title: 'Soft Skills',
        section1Stats: [
          FitCardStat('Decision Making', c.decisionMaking),
          FitCardStat('Cognitive Flexibility', c.cognitiveFlexibility),
          FitCardStat('Emotional Regulation', c.emotionalRegulation),
        ],
        section2Title: 'Hard Skills',
        section2Stats: c.hardSkills.entries
            .take(2)
            .map((e) => FitCardStat(e.key, '${e.value}%'))
            .toList(),
        tags: [...c.contractTypes, if (c.isImmediate) 'Immediately'],
        badgeText: '${c.fitScore}% Fit score',
      );

  factory FitCardData.fromJobOffer(JobOffer j) => FitCardData(
        id: j.id,
        type: FitCardType.jobOffer,
        raw: j,
        avatarUrl:
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(j.companyName.isEmpty ? j.title : j.companyName)}&background=1B3B7B&color=fff',
        title: j.title,
        subtitle: j.locationDisplay,
        primaryLabel: 'Company',
        primaryValue: '${j.companyName} | ${j.experienceLevel.label}',
        section1Title: 'Job Details',
        section1Stats: [
          FitCardStat('Workplace', j.workplaceType.label),
          FitCardStat('Employment', j.contractType.label),
          FitCardStat('Field', j.fieldOfWork),
        ],
        section2Title: 'Compensation',
        section2Stats: [
          FitCardStat('Salary', j.salaryDisplay),
        ],
        tags: [
          j.workplaceType.label,
          j.contractType.label,
          if (j.openToInternational) 'International',
        ],
        badgeText: null,
      );
}