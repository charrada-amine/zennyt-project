import 'package:equatable/equatable.dart';

/// One section of the recruiter-facing AI resume (`CandidateResume`):
/// `GET /candidates/{candidateId}/resume?jobOfferId=`.
///
/// `available == false` means the backend fell back to a static text instead of
/// an AI generation — the text is still readable, it is just not generated yet.
class ResumeSection extends Equatable {
  final bool available;
  final String textFr;
  final String textEn;

  const ResumeSection({
    required this.available,
    required this.textFr,
    required this.textEn,
  });

  factory ResumeSection.fromJson(Map<String, dynamic>? json) => ResumeSection(
        available: json?['available'] as bool? ?? false,
        textFr: json?['textFr'] as String? ?? '',
        textEn: json?['textEn'] as String? ?? '',
      );

  bool get isEmpty => textFr.trim().isEmpty && textEn.trim().isEmpty;

  /// Biased to the asked locale, falling back to whichever text is present.
  String textFor(String locale) {
    if (locale.toLowerCase().startsWith('fr')) {
      return textFr.isNotEmpty ? textFr : textEn;
    }
    return textEn.isNotEmpty ? textEn : textFr;
  }

  @override
  List<Object?> get props => [available, textFr, textEn];
}

class FitResume extends Equatable {
  final ResumeSection softSkills;
  final ResumeSection hardSkills;

  const FitResume({required this.softSkills, required this.hardSkills});

  factory FitResume.fromJson(Map<String, dynamic> json) => FitResume(
        softSkills:
            ResumeSection.fromJson(json['softSkills'] as Map<String, dynamic>?),
        hardSkills:
            ResumeSection.fromJson(json['hardSkills'] as Map<String, dynamic>?),
      );

  @override
  List<Object?> get props => [softSkills, hardSkills];
}
