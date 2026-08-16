import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/entities/game_type.dart';
import 'package:zennyt/features/games/domain/entities/mini_game.dart';
import 'package:zennyt/features/games/domain/entities/prevision_puzzle_metrics.dart';

/// Barème « Predictive Puzzle » (Tour de Hanoï) — parité mock ⇄ backend.
///
/// Chaque niveau est noté /10 : 1ᵉʳ essai (+4) · erreurs de séquence
/// (0→+3, ≤2→+2, sinon +1) · coups superflus, ratio (planned−optimal)/optimal
/// (<10 %→+3, <25 %→+2, sinon +1). Le score du mini-jeu = moyenne arrondie des
/// niveaux, /10.
void main() {
  Future<int> scoreOf(List<PrevisionPuzzleLevelMetrics> levels) async {
    final repo = GamesMockRepository();
    final session = await repo.startSession(GameType.planifik);
    final updated = await repo.submitResult(
      sessionId: session.id,
      miniGame: MiniGame.previsionPuzzle,
      metrics: PrevisionPuzzleMetrics(levels: levels),
    );
    return updated.lastAttempt!.score.rawPoints;
  }

  test('niveau parfait (1er essai, 0 erreur, plan optimal) = 10/10', () async {
    final points = await scoreOf(const [
      PrevisionPuzzleLevelMetrics(
        levelIndex: 0,
        discCount: 3,
        firstTrySuccess: true,
        sequenceErrors: 0,
        plannedMoves: 7, // = optimal (2^3 - 1)
        optimalMoves: 7,
        retries: 0,
        completed: true,
      ),
    ]);
    // +4 (1er essai) +3 (0 erreur) +3 (ratio 0 < 10 %) = 10
    expect(points, 10);
  });

  test('niveau raté (échec, 3 erreurs, +71 % de coups) = 2/10', () async {
    final points = await scoreOf(const [
      PrevisionPuzzleLevelMetrics(
        levelIndex: 0,
        discCount: 3,
        firstTrySuccess: false,
        sequenceErrors: 3,
        plannedMoves: 12, // ratio (12-7)/7 = 0.71
        optimalMoves: 7,
        retries: 1,
        completed: false,
      ),
    ]);
    // 0 (pas 1er essai) +1 (3 erreurs > 2) +1 (ratio ≥ 25 %) = 2
    expect(points, 2);
  });

  test('coups superflus dans la bande 10–25 % → +2 (niveau à 9/10)', () async {
    final points = await scoreOf(const [
      PrevisionPuzzleLevelMetrics(
        levelIndex: 0,
        discCount: 3,
        firstTrySuccess: true,
        sequenceErrors: 0,
        plannedMoves: 8, // ratio (8-7)/7 = 0.143 → bande 10–25 %
        optimalMoves: 7,
        retries: 0,
        completed: true,
      ),
    ]);
    // +4 +3 +2 = 9
    expect(points, 9);
  });

  test('moyenne arrondie sur deux niveaux (10 et 2 → 6/10)', () async {
    final points = await scoreOf(const [
      PrevisionPuzzleLevelMetrics(
        levelIndex: 0,
        discCount: 3,
        firstTrySuccess: true,
        sequenceErrors: 0,
        plannedMoves: 7,
        optimalMoves: 7,
        retries: 0,
        completed: true,
      ),
      PrevisionPuzzleLevelMetrics(
        levelIndex: 1,
        discCount: 4,
        firstTrySuccess: false,
        sequenceErrors: 3,
        plannedMoves: 26, // ratio (26-15)/15 = 0.73
        optimalMoves: 15,
        retries: 1,
        completed: false,
      ),
    ]);
    // (10 + 2) / 2 = 6
    expect(points, 6);
  });
}
