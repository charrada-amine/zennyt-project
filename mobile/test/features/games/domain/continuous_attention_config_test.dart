import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/continuous_attention_config.dart';
import 'package:zennyt/features/games/domain/entities/continuous_attention_metrics.dart';

void main() {
  test('fenêtre de réponse exacte = [0, 690)', () {
    expect(ContinuousAttentionConfig.acceptsResponseLatencyMs(0), isTrue);
    expect(ContinuousAttentionConfig.acceptsResponseLatencyMs(689), isTrue);
    expect(ContinuousAttentionConfig.acceptsResponseLatencyMs(690), isFalse);
    expect(ContinuousAttentionConfig.acceptsResponseLatencyMs(-1), isFalse);
  });

  test('FNV-1a32 UTF-8 respecte les vecteurs de référence', () {
    expect(ContinuousAttentionConfig.fnv1a32(''), 0x811C9DC5);
    expect(ContinuousAttentionConfig.fnv1a32('a'), 0xE40C292C);
    expect(ContinuousAttentionConfig.fnv1a32('foobar'), 0xBF9CF968);
  });

  test('xorshift32 respecte le vecteur unsigned de référence', () {
    final random = ContinuousAttentionRandom(1);

    expect(
      [for (var i = 0; i < 5; i++) random.nextInt(0x100000000)],
      [270369, 67634689, 2647435461, 307599695, 2398689233],
    );
  });

  group('ContinuousAttentionConfig.generateSequence', () {
    const seeds = [
      '00000000-0000-4000-8000-000000000001',
      '123e4567-e89b-12d3-a456-426614174000',
      'FFFFFFFF-FFFF-4FFF-8FFF-FFFFFFFFFFFF',
      'mock-session-1',
      'mock-session-42',
    ];

    for (final sessionId in seeds) {
      test('respecte le protocole pour $sessionId', () {
        final blocks = ContinuousAttentionConfig.generateSequence(sessionId);

        expect(blocks, hasLength(ContinuousAttentionConfig.totalBlocks));
        expect(
          blocks.expand((block) => block.trials),
          hasLength(ContinuousAttentionConfig.totalTrials),
        );
        expect(blocks.take(2).map((block) => block.phase).toSet(), {
          ContinuousAttentionPhase.xPractice,
        });
        expect(blocks.skip(2).take(20).map((block) => block.phase).toSet(), {
          ContinuousAttentionPhase.xTest,
        });
        expect(blocks.skip(22).take(2).map((block) => block.phase).toSet(), {
          ContinuousAttentionPhase.axPractice,
        });
        expect(blocks.skip(24).take(20).map((block) => block.phase).toSet(), {
          ContinuousAttentionPhase.axTest,
        });

        for (final block in blocks) {
          expect(
            block.trials,
            hasLength(ContinuousAttentionConfig.trialsPerBlock),
          );
          expect(
            block.targetCount,
            block.phase.isAx
                ? ContinuousAttentionConfig.axTargetsPerBlock
                : ContinuousAttentionConfig.xTargetsPerBlock,
          );

          if (block.phase.isAx) {
            final derivedTargets = block.trials
                .where(
                  (trial) =>
                      trial.previousLetter == 'A' && trial.currentLetter == 'X',
                )
                .length;
            expect(
              derivedTargets,
              ContinuousAttentionConfig.axTargetsPerBlock,
              reason: 'aucune cible AX accidentelle ne doit être produite',
            );
          } else {
            expect(
              block.trials.where((trial) => trial.currentLetter == 'X'),
              hasLength(ContinuousAttentionConfig.xTargetsPerBlock),
            );
          }
        }
      });
    }

    test(
      'est déterministe et sensible à la casse uniquement avant normalisation',
      () {
        List<String> flatten(String sessionId) =>
            ContinuousAttentionConfig.generateSequence(sessionId)
                .expand(
                  (block) => block.trials.map((trial) => trial.currentLetter),
                )
                .toList();

        expect(flatten(seeds.first), flatten(seeds.first));
        expect(flatten(seeds[2]), flatten(seeds[2].toLowerCase()));
        expect(flatten(seeds.first), isNot(flatten(seeds[1])));
      },
    );

    test('ne réinitialise previousLetter que deux fois', () {
      final blocks = ContinuousAttentionConfig.generateSequence(seeds.first);
      final flattened = blocks.expand((block) => block.trials).toList();
      final nullIndexes = <int>[
        for (var index = 0; index < flattened.length; index++)
          if (flattened[index].previousLetter == null) index,
      ];

      expect(nullIndexes, [0, 22 * ContinuousAttentionConfig.trialsPerBlock]);

      for (var blockIndex = 1; blockIndex < 22; blockIndex++) {
        final previousBlock = blocks[blockIndex - 1];
        final block = blocks[blockIndex];
        expect(
          block.trials.first.previousLetter,
          previousBlock.trials.last.currentLetter,
        );
      }
      for (var blockIndex = 23; blockIndex < blocks.length; blockIndex++) {
        final previousBlock = blocks[blockIndex - 1];
        final block = blocks[blockIndex];
        expect(
          block.trials.first.previousLetter,
          previousBlock.trials.last.currentLetter,
        );
      }
    });

    test('verrouille le golden vector ROSVOLD_LONG_V1', () {
      const sessionId = '00000000-0000-4000-8000-000000000001';
      final material =
          '${sessionId.toLowerCase()}|'
          '${ContinuousAttentionConfig.protocolVersion}';
      final blocks = ContinuousAttentionConfig.generateSequence(sessionId);
      final flattened = blocks
          .expand((block) => block.trials.map((trial) => trial.currentLetter))
          .join();

      expect(ContinuousAttentionConfig.fnv1a32(material), 0xFC0A124C);
      expect(ContinuousAttentionConfig.fnv1a32(flattened), 0xD9278D75);
      expect(
        blocks.first.trials.map((trial) => trial.currentLetter).join(),
        'HZNXXAJGQXXYYKEOCXFVXOXLJLNNIXH',
      );
      expect(
        blocks[22].trials.map((trial) => trial.currentLetter).join(),
        'AXHAXDNCNOJAAXVAXAXZUAXAIIPACHW',
      );
      expect(
        blocks.last.trials.map((trial) => trial.currentLetter).join(),
        'JYGAXJBYARQQKAXFSPAXXAXFYAXAXDY',
      );
    });
  });

  test('ContinuousAttentionMetrics suit les clés du contrat', () {
    const trial = ContinuousAttentionTrialMetric(
      trialIndex: 1,
      previousLetter: null,
      currentLetter: 'X',
      responseCode: 57,
      correct: 1,
      latencyMs: 312,
      scheduledOnsetMs: 0,
      actualOnsetMs: 2,
      responseTimestampMs: 314,
      actualDisplayDurationMs: 690,
      actualIsiDurationMs: 230,
      inputSource: ContinuousAttentionInputSource.keyboard,
      extraResponseCount: 0,
      interrupted: false,
    );
    final metrics = ContinuousAttentionMetrics(
      blocks: [
        ContinuousAttentionBlockMetric(
          phase: ContinuousAttentionPhase.xPractice,
          blockIndex: 1,
          trials: [trial],
        ),
      ],
      sessionCompleted: true,
      interrupted: false,
      backgroundEventCount: 0,
      droppedFrameCount: 0,
    );

    expect(metrics.toJson(), {
      'protocolVersion': 'ROSVOLD_LONG_V1',
      'blocks': [
        {
          'phase': 'X_PRACTICE',
          'blockIndex': 1,
          'trials': [
            {
              'trialIndex': 1,
              'previousLetter': null,
              'currentLetter': 'X',
              'responseCode': 57,
              'correct': 1,
              'latencyMs': 312,
              'scheduledOnsetMs': 0,
              'actualOnsetMs': 2,
              'responseTimestampMs': 314,
              'actualDisplayDurationMs': 690,
              'actualIsiDurationMs': 230,
              'inputSource': 'KEYBOARD',
              'extraResponseCount': 0,
              'interrupted': false,
            },
          ],
        },
      ],
      'sessionCompleted': true,
      'interrupted': false,
      'backgroundEventCount': 0,
      'droppedFrameCount': 0,
    });
  });

  test('séquences, blocs, métriques et indicateurs sont immuables', () {
    final sequence = ContinuousAttentionConfig.generateSequence(
      '00000000-0000-4000-8000-000000000001',
    );
    expect(() => sequence.clear(), throwsUnsupportedError);
    expect(() => sequence.first.trials.clear(), throwsUnsupportedError);

    const trial = ContinuousAttentionTrialMetric(
      trialIndex: 1,
      previousLetter: null,
      currentLetter: 'X',
      responseCode: 0,
      correct: 0,
      latencyMs: null,
      scheduledOnsetMs: 0,
      actualOnsetMs: 0,
      responseTimestampMs: null,
      actualDisplayDurationMs: 690,
      actualIsiDurationMs: 230,
      inputSource: null,
      extraResponseCount: 0,
      interrupted: false,
    );
    final sourceTrials = <ContinuousAttentionTrialMetric>[trial];
    final block = ContinuousAttentionBlockMetric(
      phase: ContinuousAttentionPhase.xPractice,
      blockIndex: 1,
      trials: sourceTrials,
    );
    sourceTrials.clear();
    expect(block.trials, hasLength(1));
    expect(() => block.trials.clear(), throwsUnsupportedError);

    final sourceBlocks = <ContinuousAttentionBlockMetric>[block];
    final metrics = ContinuousAttentionMetrics(
      blocks: sourceBlocks,
      sessionCompleted: false,
      interrupted: false,
      backgroundEventCount: 0,
      droppedFrameCount: 0,
    );
    sourceBlocks.clear();
    expect(metrics.blocks, hasLength(1));
    expect(() => metrics.blocks.clear(), throwsUnsupportedError);

    final indicators = ContinuousAttentionIndicators.fromJson({
      'xPhase': {'phase': 'X_TEST'},
      'axPhase': {'phase': 'AX_TEST'},
      'epochs': <dynamic>[],
      'validityIssues': <dynamic>['TIMING_DEVIATION'],
    });
    expect(() => indicators.epochs.clear(), throwsUnsupportedError);
    expect(() => indicators.validityIssues.clear(), throwsUnsupportedError);
  });
}
