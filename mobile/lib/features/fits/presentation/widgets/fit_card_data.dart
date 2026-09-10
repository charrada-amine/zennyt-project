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
        // F10 (FITSCORE_REMEDIATION.md §3 index F10): one honest row from the
        // real aggregate score, not three fabricated per-module rows the
        // backend doesn't provide (see CandidateProfile.softSkillsLevel).
        section1Title: 'Soft Skills',
        section1Stats: [
          FitCardStat('Overall', c.softSkillsLevel),
        ],
        // F17 (FITSCORE_REMEDIATION.md §3 index F17) contexts 2/3 — "Liste de
        // candidats" — and F29 (§10 #8): when there's no hard-skill score
        // (no QCM on this offer), say so explicitly and frame it as the
        // standard mode, not a degraded one — not just an empty section.
        section2Title: 'Hard Skills',
        section2Stats: c.hardSkills.isNotEmpty
            ? c.hardSkills.entries.take(2).map((e) => FitCardStat(e.key, '${e.value}%')).toList()
            : const [FitCardStat('Based on', 'Soft skills only (standard)')],
        tags: [
          ...c.contractTypes,
          if (c.isImmediate) 'Immediately',
          // F16 (FITSCORE_REMEDIATION.md §3 index F16): partialData is
          // computed and contracted but was never surfaced by any client.
          if (c.partialData) 'Partial data',
        ],
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
        // F17 (FITSCORE_REMEDIATION.md §3 index F17) context 1 — "Page de
        // matching (avant QCM)": a single Fit Score % label, no sub-line
        // (candidate hasn't necessarily taken a hard-skills test at this
        // stage). Was hardcoded null even though the backend already sends
        // fitScore on this response.
        badgeText: j.fitScore != null ? '${j.fitScore}% Fit score' : null,
      );
}