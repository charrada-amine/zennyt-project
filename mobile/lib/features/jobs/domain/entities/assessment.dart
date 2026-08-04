import 'package:equatable/equatable.dart';

class Question extends Equatable {
  final String id;
  final int order;
  final String text;
  final List<String> options;
  final int correctOptionIndex;

  const Question({
    required this.id,
    required this.order,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
  });

  Question copyWith({
    String? id,
    int? order,
    String? text,
    List<String>? options,
    int? correctOptionIndex,
  }) {
    return Question(
      id: id ?? this.id,
      order: order ?? this.order,
      text: text ?? this.text,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
    );
  }

  @override
  List<Object?> get props => [id, order, text, options, correctOptionIndex];
}

class Assessment extends Equatable {
  final String id;
  final String recruiterId;
  final String title;
  final int timeLimitSeconds;
  final int maxQuestions;
  final List<Question> questions;
  final DateTime createdAt;
  final String? shareableLink;

  const Assessment({
    required this.id,
    required this.recruiterId,
    required this.title,
    required this.timeLimitSeconds,
    required this.maxQuestions,
    required this.questions,
    required this.createdAt,
    this.shareableLink,
  });

  Assessment copyWith({
    String? id,
    String? recruiterId,
    String? title,
    int? timeLimitSeconds,
    int? maxQuestions,
    List<Question>? questions,
    DateTime? createdAt,
    String? shareableLink,
  }) {
    return Assessment(
      id: id ?? this.id,
      recruiterId: recruiterId ?? this.recruiterId,
      title: title ?? this.title,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      maxQuestions: maxQuestions ?? this.maxQuestions,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      shareableLink: shareableLink ?? this.shareableLink,
    );
  }

  String get durationDisplay {
    final minutes = timeLimitSeconds ~/ 60;
    return '$minutes min';
  }

  @override
  List<Object?> get props => [
    id, recruiterId, title, timeLimitSeconds,
    maxQuestions, questions, createdAt, shareableLink,
  ];
}
