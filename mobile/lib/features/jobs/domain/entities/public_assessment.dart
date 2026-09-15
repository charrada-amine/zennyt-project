import 'package:equatable/equatable.dart';

/// Public projection of a shared hard-skills test (`GET /tests/{token}`).
///
/// Contains **no** correct answers — see recruitment contract §5.7. Used by the
/// recruiter preview screen so a shared link can be sanity-checked before it is
/// sent to candidates.
class PublicAssessmentQuestion extends Equatable {
  final String id;
  final int order;
  final String text;
  final List<String> options;

  const PublicAssessmentQuestion({
    required this.id,
    required this.order,
    required this.text,
    required this.options,
  });

  factory PublicAssessmentQuestion.fromJson(Map<String, dynamic> json) =>
      PublicAssessmentQuestion(
        id: json['id']?.toString() ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        text: json['text'] as String? ?? '',
        options: List<String>.from(json['options'] as List? ?? const []),
      );

  @override
  List<Object?> get props => [id, order, text, options];
}

class PublicAssessment extends Equatable {
  final String id;
  final String title;
  final int questionCount;
  final int timeLimitSeconds;
  final List<PublicAssessmentQuestion> questions;

  const PublicAssessment({
    required this.id,
    required this.title,
    required this.questionCount,
    required this.timeLimitSeconds,
    required this.questions,
  });

  factory PublicAssessment.fromJson(Map<String, dynamic> json) => PublicAssessment(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        questionCount: (json['questionCount'] as num?)?.toInt() ??
            (json['questions'] as List? ?? const []).length,
        timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 0,
        questions: (json['questions'] as List? ?? const [])
            .map((q) => PublicAssessmentQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, title, questionCount, timeLimitSeconds];
}
