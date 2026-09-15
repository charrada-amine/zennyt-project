import 'package:equatable/equatable.dart';

/// Hard-skills test attempt / result domain models.
///
/// Mirrors `TestAttemptStarted`, `TestResult`, `TestResultListItem`,
/// `TestResultsSummary` and `TestResultDetail` from
/// `contracts/recruitment.openapi.yaml`. The server mixes questions and options
/// per attempt, so `PresentedQuestion.options` must be sent back as
/// `selectedOptionIndex` in the presented order — never the original one.
enum TestResultStatus {
  completed('COMPLETED'),
  timeout('TIMEOUT'),
  abandoned('ABANDONED');

  final String value;
  const TestResultStatus(this.value);

  static TestResultStatus fromString(String? v) => TestResultStatus.values
      .firstWhere((e) => e.value == v, orElse: () => TestResultStatus.completed);

  String get label {
    switch (this) {
      case TestResultStatus.completed:
        return 'Completed';
      case TestResultStatus.timeout:
        return 'Timed out';
      case TestResultStatus.abandoned:
        return 'Abandoned';
    }
  }
}

class PresentedQuestion extends Equatable {
  final String id;
  final int order;
  final String text;
  final List<String> options;

  const PresentedQuestion({
    required this.id,
    required this.order,
    required this.text,
    required this.options,
  });

  factory PresentedQuestion.fromJson(Map<String, dynamic> json) => PresentedQuestion(
        id: json['id'] as String,
        order: (json['order'] as num?)?.toInt() ?? 0,
        text: json['text'] as String? ?? '',
        options: List<String>.from(json['options'] as List? ?? const []),
      );

  @override
  List<Object?> get props => [id, order, text, options];
}

class TestAttemptStarted extends Equatable {
  final String attemptId;
  final String jobOfferId;
  final int timeLimitSeconds;
  final DateTime? expiresAt;
  final List<PresentedQuestion> questions;

  const TestAttemptStarted({
    required this.attemptId,
    required this.jobOfferId,
    required this.timeLimitSeconds,
    required this.expiresAt,
    required this.questions,
  });

  factory TestAttemptStarted.fromJson(Map<String, dynamic> json) => TestAttemptStarted(
        attemptId: json['attemptId'] as String,
        jobOfferId: json['jobOfferId'] as String? ?? '',
        timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 0,
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'] as String)
            : null,
        questions: (json['questions'] as List? ?? const [])
            .map((q) => PresentedQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [attemptId, jobOfferId, timeLimitSeconds, expiresAt, questions];
}

class TestAttemptAnswer extends Equatable {
  final String questionId;
  final int selectedOptionIndex;

  const TestAttemptAnswer({required this.questionId, required this.selectedOptionIndex});

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'selectedOptionIndex': selectedOptionIndex,
      };

  @override
  List<Object?> get props => [questionId, selectedOptionIndex];
}

class MatchedCandidateSummary extends Equatable {
  final String id;
  final String fullName;
  final String avatarUrl;

  const MatchedCandidateSummary({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
  });

  factory MatchedCandidateSummary.fromJson(Map<String, dynamic> json) =>
      MatchedCandidateSummary(
        id: json['id']?.toString() ?? '',
        fullName: json['fullName'] as String? ?? 'Candidate',
        avatarUrl: json['avatarUrl'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, fullName, avatarUrl];
}

/// Candidate-facing result — no answer key, no breakdown.
class TestResult extends Equatable {
  final String id;
  final String jobOfferId;
  final String hardSkillTestId;
  final String candidateId;
  final int score;
  final int percentage;
  final bool passed;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int duration;
  final TestResultStatus status;

  const TestResult({
    required this.id,
    required this.jobOfferId,
    required this.hardSkillTestId,
    required this.candidateId,
    required this.score,
    required this.percentage,
    required this.passed,
    required this.startedAt,
    required this.completedAt,
    required this.duration,
    required this.status,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        id: json['id']?.toString() ?? '',
        jobOfferId: json['jobOfferId']?.toString() ?? '',
        hardSkillTestId: json['hardSkillTestId']?.toString() ?? '',
        candidateId: json['candidateId']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toInt() ?? 0,
        passed: json['passed'] as bool? ?? false,
        startedAt: json['startedAt'] != null
            ? DateTime.tryParse(json['startedAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        duration: (json['duration'] as num?)?.toInt() ?? 0,
        status: TestResultStatus.fromString(json['status'] as String?),
      );

  @override
  List<Object?> get props => [id, percentage, passed, status, completedAt];
}

/// Recruiter-facing list row, joined to the candidate projection.
class TestResultListItem extends Equatable {
  final String id;
  final MatchedCandidateSummary candidate;
  final int score;
  final int percentage;
  final bool passed;
  final int duration;
  final TestResultStatus status;
  final DateTime? completedAt;

  const TestResultListItem({
    required this.id,
    required this.candidate,
    required this.score,
    required this.percentage,
    required this.passed,
    required this.duration,
    required this.status,
    required this.completedAt,
  });

  factory TestResultListItem.fromJson(Map<String, dynamic> json) => TestResultListItem(
        id: json['id']?.toString() ?? '',
        candidate: MatchedCandidateSummary.fromJson(
          json['candidate'] as Map<String, dynamic>? ?? const {},
        ),
        score: (json['score'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toInt() ?? 0,
        passed: json['passed'] as bool? ?? false,
        duration: (json['duration'] as num?)?.toInt() ?? 0,
        status: TestResultStatus.fromString(json['status'] as String?),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, percentage, passed, status, completedAt];
}

class TestResultPage extends Equatable {
  final List<TestResultListItem> content;
  final int totalElements;

  const TestResultPage({required this.content, required this.totalElements});

  factory TestResultPage.fromJson(Map<String, dynamic> json) {
    final page = json['page'] as Map<String, dynamic>? ?? const {};
    return TestResultPage(
      content: (json['content'] as List? ?? const [])
          .map((e) => TestResultListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: (page['totalElements'] as num?)?.toInt() ??
          (json['content'] as List? ?? const []).length,
    );
  }

  @override
  List<Object?> get props => [content, totalElements];
}

class TestResultsSummary extends Equatable {
  final int candidateCount;
  final int passedCount;
  final int successRate;

  const TestResultsSummary({
    required this.candidateCount,
    required this.passedCount,
    required this.successRate,
  });

  factory TestResultsSummary.fromJson(Map<String, dynamic> json) => TestResultsSummary(
        candidateCount: (json['candidateCount'] as num?)?.toInt() ?? 0,
        passedCount: (json['passedCount'] as num?)?.toInt() ?? 0,
        successRate: (json['successRate'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [candidateCount, passedCount, successRate];
}

class TestAnswerBreakdownItem extends Equatable {
  final String questionId;
  final String questionText;
  final String selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;

  const TestAnswerBreakdownItem({
    required this.questionId,
    required this.questionText,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  factory TestAnswerBreakdownItem.fromJson(Map<String, dynamic> json) =>
      TestAnswerBreakdownItem(
        questionId: json['questionId']?.toString() ?? '',
        questionText: json['questionText'] as String? ?? '',
        selectedAnswer: json['selectedAnswer'] as String? ?? '',
        correctAnswer: json['correctAnswer'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [questionId, isCorrect];
}

class TestResultDetail extends Equatable {
  final String id;
  final MatchedCandidateSummary candidate;
  final int score;
  final int percentage;
  final bool passed;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int duration;
  final TestResultStatus status;
  final List<TestAnswerBreakdownItem> answerBreakdown;

  const TestResultDetail({
    required this.id,
    required this.candidate,
    required this.score,
    required this.percentage,
    required this.passed,
    required this.startedAt,
    required this.completedAt,
    required this.duration,
    required this.status,
    required this.answerBreakdown,
  });

  factory TestResultDetail.fromJson(Map<String, dynamic> json) => TestResultDetail(
        id: json['id']?.toString() ?? '',
        candidate: MatchedCandidateSummary.fromJson(
          json['candidate'] as Map<String, dynamic>? ?? const {},
        ),
        score: (json['score'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toInt() ?? 0,
        passed: json['passed'] as bool? ?? false,
        startedAt: json['startedAt'] != null
            ? DateTime.tryParse(json['startedAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        duration: (json['duration'] as num?)?.toInt() ?? 0,
        status: TestResultStatus.fromString(json['status'] as String?),
        answerBreakdown: (json['answerBreakdown'] as List? ?? const [])
            .map((e) => TestAnswerBreakdownItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, percentage, passed, status];
}
