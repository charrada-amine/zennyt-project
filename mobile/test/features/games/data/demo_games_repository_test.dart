import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/demo_games_repository.dart';
import 'package:zennyt/features/games/domain/entities/decision_form.dart';
import 'package:zennyt/features/games/domain/entities/decision_metrics.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/presentation/view/je_decide_results.dart';

/// Garde-fou du repository de DÉMO (APK de revue client).
///
/// Il ne couvre que ce qui distingue la démo du mock : « Je décide » doit
/// devenir jouable ET notable hors ligne, sans que le reste du module bouge.
void main() {
  late DemoGamesRepository repo;

  setUp(() => repo = DemoGamesRepository());

  Future<DecisionForm> startAndFetch() async {
    final session = await repo.startSession(GameType.decision);
    return repo.decisionItems(session.id);
  }

  test('la forme de démo sert 30 items, 6 par dimension', () async {
    final form = await startAndFetch();

    expect(form.totalItems, 30);
    expect(form.itemsPerDimension, 6);
    for (final dimension in DecisionDimension.values) {
      expect(
        form.items.where((i) => i.dimension == dimension).length,
        6,
        reason: 'dimension ${dimension.wire}',
      );
    }
  });

  test('les items ne portent aucune clé de correction', () async {
    final form = await startAndFetch();

    // Le contrat vaut aussi pour la démo : `DecisionFormOption` n'expose ni
    // qualité ni points. Ce test verrouille l'absence de fuite via le JSON.
    for (final item in form.items) {
      expect(item.options, isNotEmpty);
      for (final option in item.options) {
        expect(option.optionId, isNotEmpty);
        expect(option.label, isNotEmpty);
      }
    }
  });

  test('les trois formats sont représentés', () async {
    final form = await startAndFetch();
    final formats = form.items.map((i) => i.format).toSet();

    expect(formats, contains(DecisionItemFormat.standard));
    expect(formats, contains(DecisionItemFormat.temporalDecision));
    expect(formats, contains(DecisionItemFormat.coherencePair));

    // Un item chronométré porte sa limite ; les autres non.
    for (final item in form.items) {
      if (item.isTimed) {
        expect(item.timeLimitMs, isNotNull);
      }
    }
    // Les items de paire partagent un pairId.
    final paired = form.items.where((i) => i.pairId != null).toList();
    expect(paired, hasLength(2));
    expect(paired.first.pairId, paired.last.pairId);
  });

  test('tout choisir en premier → score maximal ; en dernier → score nul',
      () async {
    Future<int> playPicking(int Function(int optionCount) chooseIndex) async {
      final session = await repo.startSession(GameType.decision);
      final form = await repo.decisionItems(session.id);
      final answers = [
        for (final item in form.items)
          DecisionItemResponse(
            itemId: item.itemId,
            dimension: item.dimension,
            selectedOptionId:
                item.options[chooseIndex(item.options.length)].optionId,
            responseTimeMs: 4000,
          ),
      ];
      final result = await repo.submitResult(
        sessionId: session.id,
        miniGame: MiniGame.decisionCore,
        metrics: DecisionMetrics(items: answers),
      );
      return result.lastAttempt!.score.rawPoints;
    }

    // La 1ʳᵉ option de chaque item vaut 3 points, la dernière 0 — c'est ainsi
    // que la banque de démo est écrite.
    expect(await playPicking((_) => 0), 100);
    expect(await playPicking((count) => count - 1), 0);
  });

  test('le profil de résultats se reconstruit depuis la session notée',
      () async {
    final session = await repo.startSession(GameType.decision);
    final form = await repo.decisionItems(session.id);
    final result = await repo.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.decisionCore,
      metrics: DecisionMetrics(
        items: [
          for (final item in form.items)
            DecisionItemResponse(
              itemId: item.itemId,
              dimension: item.dimension,
              selectedOptionId: item.options.first.optionId,
              responseTimeMs: 3200,
            ),
        ],
      ),
    );

    // C'est ce que lit l'écran de résultats : sans lignes `criterion` par
    // dimension, le radar reste vide.
    final profile = DecisionProfile.fromSession(result);
    expect(profile.score, 100);
    expect(profile.dimensions, hasLength(5));
    for (final dimension in profile.dimensions) {
      expect(dimension.exploitable, isTrue, reason: dimension.code);
      expect(dimension.points, 18);
      expect(dimension.percent, 100);
    }
  });

  test('une réponse non renseignée ne rapporte aucun point', () async {
    final session = await repo.startSession(GameType.decision);
    final form = await repo.decisionItems(session.id);
    final result = await repo.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.decisionCore,
      metrics: DecisionMetrics(
        items: [
          for (final item in form.items)
            DecisionItemResponse(
              itemId: item.itemId,
              dimension: item.dimension,
              selectedOptionId: null,
              answered: false,
              responseTimeMs: 0,
            ),
        ],
      ),
    );

    expect(result.lastAttempt!.score.rawPoints, 0);
  });
}
