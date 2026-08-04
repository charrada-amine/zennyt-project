import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';

/// Résultat d'une tentative renvoyé par `POST /assessment-attempts`.
class AttemptResult {
  final String id;
  final int score;
  final bool passed;
  const AttemptResult({
    required this.id,
    required this.score,
    required this.passed,
  });
}

/// Une question QCM à envoyer lors de la création d'un test (recruteur).
class NewQuestion {
  final String text;
  final List<String> options; // 4 réponses
  final int correctOptionIndex;
  const NewQuestion({
    required this.text,
    required this.options,
    required this.correctOptionIndex,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'options': options,
        'correctOptionIndex': correctOptionIndex,
      };
}

/// Écritures liées aux évaluations.
///
/// - Candidat : `submitAttempt` → `POST /assessment-attempts`.
/// - Recruteur : `createAssessment` → `POST /assessments` (création manuelle ;
///   la génération par IA n'est pas branchée ici).
class AssessmentRemoteDataSource {
  final Dio dio;
  AssessmentRemoteDataSource(this.dio);

  /// POST /assessment-attempts — soumet les réponses du candidat, renvoie le score.
  Future<AttemptResult> submitAttempt({
    required String assessmentId,
    required String jobOfferId,
    required List<int> answers,
  }) async {
    try {
      final res = await dio.post('/assessment-attempts', data: {
        'assessmentId': assessmentId,
        'jobOfferId': jobOfferId,
        'answers': answers,
      });
      final data = res.data as Map<String, dynamic>;
      return AttemptResult(
        id: data['id'] as String,
        score: (data['score'] as num?)?.toInt() ?? 0,
        passed: data['passed'] == true,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// POST /assessments — crée un test (recruteur). Renvoie l'id du test créé.
  Future<String> createAssessment({
    required String title,
    required List<NewQuestion> questions,
  }) async {
    try {
      final res = await dio.post('/assessments', data: {
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
      });
      final data = res.data as Map<String, dynamic>;
      return data['id'] as String;
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
