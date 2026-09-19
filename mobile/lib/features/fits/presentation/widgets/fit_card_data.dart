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

  /// Job-offer extras used by the compact "Fit Scores" cards and the readable
  /// detail card. Null on candidate cards.
  final String? companyName;
  final String? experienceLabel;
  final String? workplaceLabel;
  final String? contractLabel;
  final String? salaryDisplay;
  final String? description;
  final DateTime? postedAt;

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
    this.companyName,
    this.experienceLabel,
    this.workplaceLabel,
    this.contractLabel,
    this.salaryDisplay,
    this.description,
    this.postedAt,
  });

  factory FitCardData.fromCandidate(CandidateProfile c) => FitCardData(
        id: c.id,
        type: FitCardType.candidate,
        raw: c,
        avatarUrl: c.avatarUrl,
        title: c.name,
        subtitle: c.location,
        primaryLabel: 'Target role',
        primaryValue: _joinParts([c.targetRole, c.seniority], empty: 'Not specified yet'),
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
        experienceLabel: c.seniority.isEmpty ? null : c.seniority,
        tags: [
          ...c.contractTypes,
          if (c.isImmediate) 'Immediately',
          // F16 (FITSCORE_REMEDIATION.md §3 index F16): partialData is
          // computed and contracted but was never surfaced by any client.
          if (c.partialData) 'Partial data',
        ],
        // Pas encore de score (aucun jeu joué) ≠ un score de 0 % : ne pas afficher
        // un « 0 % » qui se lit comme un très mauvais profil.
        badgeText: c.fitScore > 0 ? '${c.fitScore}% Fit score' : 'No Fit Score yet',
      );

  factory FitCardData.fromJobOffer(JobOffer j) => FitCardData(
        id: j.id,
        type: FitCardType.jobOffer,
        raw: j,
        avatarUrl:
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(j.companyName.isEmpty ? j.title : j.companyName)}&background=1B3B7B&color=fff',
        title: j.title,
        subtitle: j.locationDisplay,
        companyName: j.companyName,
        primaryLabel: 'Company',
        primaryValue: _joinParts([j.companyName, j.experienceLevel.label]),
        experienceLabel: j.experienceLevel.label,
        workplaceLabel: j.workplaceType.label,
        contractLabel: j.contractType.label,
        salaryDisplay: j.salaryDisplay,
        description: j.description,
        postedAt: j.postedAt,
        section1Title: 'About the job',
        section1Stats: const [],
        section2Title: 'Compensation',
        section2Stats: [
          FitCardStat('Salary', j.salaryDisplay.isEmpty ? 'Not disclosed' : j.salaryDisplay),
        ],
        tags: [
          j.experienceLevel.label,
          j.contractType.label,
          j.workplaceType.label,
          if (j.openToInternational) 'International candidates welcome',
        ],
        // F17 (FITSCORE_REMEDIATION.md §3 index F17) context 1 — "Page de
        // matching (avant QCM)": a single Fit Score % label, no sub-line
        // (candidate hasn't necessarily taken a hard-skills test at this
        // stage). Was hardcoded null even though the backend already sends
        // fitScore on this response.
        badgeText: j.fitScore != null ? '${j.fitScore}% Fit score' : null,
      );
}

/// Assemble les morceaux non vides (« Nexa Digital · Senior ») : un champ vide
/// laissait sinon un séparateur orphelin (« | Manager »).
String _joinParts(List<String?> parts, {String empty = '—'}) {
  final kept = parts.whereType<String>().map((p) => p.trim()).where((p) => p.isNotEmpty);
  return kept.isEmpty ? empty : kept.join(' · ');
}

/// « Posted 2 days ago » — compact relative label for job cards.
String postedAgoLabel(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays <= 0) {
    if (diff.inHours <= 0) return 'Posted just now';
    return diff.inHours == 1 ? 'Posted 1 hour ago' : 'Posted ${diff.inHours} hours ago';
  }
  if (diff.inDays == 1) return 'Posted 1 day ago';
  if (diff.inDays < 30) return 'Posted ${diff.inDays} days ago';
  final months = (diff.inDays / 30).floor();
  return months <= 1 ? 'Posted 1 month ago' : 'Posted $months months ago';
}
