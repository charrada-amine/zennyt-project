import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/demo_games_repository.dart';
import 'package:zennyt/features/games/domain/config/decision_provisional_rules.dart';
import 'package:zennyt/features/games/domain/entities/decision_form.dart';
import 'package:zennyt/features/games/domain/entities/game_score.dart';
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

  /// Les seuils de niveau étaient recopiés dans le dépôt de démo — 75 / 55 / 40
  /// — face aux 75 / 60 / 45 de la couche provisoire. Un même score tombait donc
  /// « Normal » d'un côté et « Borderline » de l'autre, sur cinq points d'écart.
  /// Seule la couche provisoire trace ce qui vient de la fiche du psychologue et
  /// ce qui est déduit : elle fait foi, et ce test empêche la copie de revenir.
  test('le niveau de démo suit la couche provisoire', () async {
    /// Joue toute la forme en prenant sur chaque item l'option de rang [rank].
    /// Les items de démo listent leurs options de la meilleure à la pire : le
    /// score décroît donc avec le rang, ce qui balaie les quatre niveaux.
    Future<GameScore> playAll(int rank) async {
      final session = await repo.startSession(GameType.decision);
      final items = (await repo.decisionItems(session.id)).items;
      final out = await repo.submitResult(
        sessionId: session.id,
        miniGame: MiniGame.decisionCore,
        metrics: DecisionMetrics(
          items: [
            for (final i in items)
              DecisionItemResponse(
                itemId: i.itemId,
                dimension: i.dimension,
                selectedOptionId:
                    i.options[rank.clamp(0, i.options.length - 1)].optionId,
                responseTimeMs: 4000,
                answered: true,
                decisionChangesCount: 0,
              ),
          ],
        ),
      );
      return out.lastAttempt!.score;
    }

    for (var rank = 0; rank < 4; rank++) {
      final score = await playAll(rank);
      expect(
        score.level,
        DecisionProvisionalRules.levelForScw(score.normalized),
        reason:
            'rang $rank → ${score.normalized.toStringAsFixed(1)} : le niveau '
            'doit être celui de la couche provisoire',
      );
    }

    // La frontière qui divergeait : l'ancien barème de démo disait « Normal »
    // à 57, la couche provisoire dit « Borderline ».
    expect(DecisionProvisionalRules.levelForScw(57), 'Borderline');
  });

}
