import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_repository_impl.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';

void main() {
  const metrics = DecisionMetrics(
    sessionLanguage: 'fr',
    items: [
      DecisionItemResponse(
        itemId: 'ER-1',
        dimension: DecisionDimension.er,
        selectedOptionId: 'ER-1-A',
        responseTimeMs: 3200,
        decisionChangesCount: 1,
      ),
      DecisionItemResponse(
        itemId: 'DT-1',
        dimension: DecisionDimension.dt,
        responseTimeMs: 8400,
        answered: false,
      ),
    ],
  );

  test(
    'POST transmet decisionItems au DTO serveur, jamais items ni points',
    () async {
      final adapter = _DecisionAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
        ..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final session = await GamesRepositoryImpl(dio).submitResult(
        sessionId: 'session-test',
        miniGame: MiniGame.decisionCore,
        metrics: metrics,
      );

      final request = adapter.request!;
      expect(request.method, 'POST');
      expect(request.path, '/games/sessions/session-test/results');
      final body = request.data as Map<String, dynamic>;
      expect(body['miniGame'], 'DECISION_CORE');
      final raw = body['metrics'] as Map<String, dynamic>;
      expect(raw.containsKey('items'), isFalse);
      expect(raw['sessionLanguage'], 'fr');
      expect(raw['administrationMode'], 'SUPERVISED');
      final answers = raw['decisionItems'] as List;
      expect(answers, hasLength(2));
      expect(answers.first['selectedOptionId'], 'ER-1-A');
      expect(answers.first['responseTimeMs'], 3200);
      expect(answers.first['decisionChangesCount'], 1);
      expect(answers.last['answered'], isFalse);
      expect(answers.last.containsKey('selectedOptionId'), isFalse);
      expect(raw.containsKey('score'), isFalse);
      expect(session.lastAttempt!.score.rawPoints, 71);
    },
  );
}

class _DecisionAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    final metrics = (options.data as Map)['metrics'] as Map;
    // Même rejet strict que SubmitResultRequest.Metrics : la faute initiale
    // provoquait un HTTP 400, invisible aux tests de repository simulé.
    if (metrics.containsKey('items') || !metrics.containsKey('decisionItems')) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Unrecognized field "items"'}),
        400,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'id': 'session-test',
        'gameType': 'DECISION',
        'status': 'COMPLETED',
        'compositeRaw': 71,
        'compositeMax': 100,
        'normalized': 0.71,
        'startedAt': '2026-09-17T10:00:00Z',
        'attempts': [
          {
            'miniGame': 'DECISION_CORE',
            'score': {
              'rawPoints': 71,
              'maxPoints': 100,
              'normalized': 0.71,
              'level': 'Normal',
            },
            'recordedAt': '2026-09-17T10:01:00Z',
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
