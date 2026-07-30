import 'dart:convert';

/// Phase du protocole Long Rosvold X/AX utilisé par « Je continue ».
enum ContinuousAttentionPhase {
  xPractice('X_PRACTICE'),
  xTest('X_TEST'),
  axPractice('AX_PRACTICE'),
  axTest('AX_TEST');

  const ContinuousAttentionPhase(this.wire);

  final String wire;

  bool get isPractice =>
      this == ContinuousAttentionPhase.xPractice ||
      this == ContinuousAttentionPhase.axPractice;

  bool get isTest => !isPractice;

  bool get isAx =>
      this == ContinuousAttentionPhase.axPractice ||
      this == ContinuousAttentionPhase.axTest;

  static ContinuousAttentionPhase fromWire(String value) =>
      ContinuousAttentionPhase.values.firstWhere(
        (phase) => phase.wire == value,
      );
}

/// Tempo injectable du flux de stimuli.
///
/// [production] est le protocole validé et ne doit jamais être raccourci dans
/// l'application. Les tests de widgets peuvent injecter un tempo accéléré sans
/// modifier les constantes de production ni les séquences générées.
class ContinuousAttentionTempo {
  const ContinuousAttentionTempo({
    required this.stimulusDuration,
    required this.interStimulusDuration,
    required this.scheduledRestDuration,
  });

  static const production = ContinuousAttentionTempo(
    stimulusDuration: Duration(
      milliseconds: ContinuousAttentionConfig.stimulusDurationMs,
    ),
    interStimulusDuration: Duration(
      milliseconds: ContinuousAttentionConfig.interStimulusDurationMs,
    ),
    scheduledRestDuration: Duration(minutes: 2),
  );

  final Duration stimulusDuration;
  final Duration interStimulusDuration;
  final Duration scheduledRestDuration;

  Duration get trialDuration => stimulusDuration + interStimulusDuration;
}

/// Paramètres contractuels et générateur déterministe de « Je continue ».
///
/// Le serveur reconstruit exactement la même séquence depuis l'identifiant de
/// session. Toute modification de l'algorithme doit donc être répercutée dans
/// `ContinuousAttentionSequenceGenerator.java` au cours de la même PR.
class ContinuousAttentionConfig {
  const ContinuousAttentionConfig._();

  static const protocolVersion = 'ROSVOLD_LONG_V1';
  static const stimulusDurationMs = 690;
  static const interStimulusDurationMs = 230;
  static const timingToleranceMs = 100;
  static const trialsPerBlock = 31;
  static const practiceBlocksPerFamily = 2;
  static const testBlocksPerFamily = 20;
  static const xTargetsPerBlock = 8;
  static const axTargetsPerBlock = 6;
  static const totalBlocks =
      2 * (practiceBlocksPerFamily + testBlocksPerFamily);
  static const totalTrials = totalBlocks * trialsPerBlock;

  static const _xDistractors = 'ABCDEFGHIJKLMNOPQRSTUVWYZ';
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// La fenêtre de réponse contractuelle est semi-ouverte : [0, 690).
  static bool acceptsResponseLatencyMs(int latencyMs) =>
      latencyMs >= 0 && latencyMs < stimulusDurationMs;

  /// Produit les 44 blocs dans l'ordre contractuel :
  /// X_PRACTICE, X_TEST, AX_PRACTICE, AX_TEST.
  ///
  /// `previousLetter` est réinitialisée uniquement deux fois : au premier
  /// essai de la famille X, puis au premier essai de la famille AX. Elle reste
  /// continue entre pratique/test et entre blocs d'une même famille.
  static List<ContinuousAttentionBlockSequence> generateSequence(
    String sessionId,
  ) {
    final random = ContinuousAttentionRandom(
      fnv1a32('${sessionId.toLowerCase()}|$protocolVersion'),
    );
    final blocks = <ContinuousAttentionBlockSequence>[];

    String? previousLetter;
    previousLetter = _appendXBlocks(
      blocks: blocks,
      random: random,
      phase: ContinuousAttentionPhase.xPractice,
      count: practiceBlocksPerFamily,
      previousLetter: previousLetter,
    );
    _appendXBlocks(
      blocks: blocks,
      random: random,
      phase: ContinuousAttentionPhase.xTest,
      count: testBlocksPerFamily,
      previousLetter: previousLetter,
    );

    // Deuxième et dernière réinitialisation du protocole.
    previousLetter = null;
    previousLetter = _appendAxBlocks(
      blocks: blocks,
      random: random,
      phase: ContinuousAttentionPhase.axPractice,
      count: practiceBlocksPerFamily,
      previousLetter: previousLetter,
    );
    _appendAxBlocks(
      blocks: blocks,
      random: random,
      phase: ContinuousAttentionPhase.axTest,
      count: testBlocksPerFamily,
      previousLetter: previousLetter,
    );

    return List.unmodifiable(blocks);
  }

  static String? _appendXBlocks({
    required List<ContinuousAttentionBlockSequence> blocks,
    required ContinuousAttentionRandom random,
    required ContinuousAttentionPhase phase,
    required int count,
    required String? previousLetter,
  }) {
    var previous = previousLetter;
    for (var blockIndex = 1; blockIndex <= count; blockIndex++) {
      final letters = <String>[
        ...List.filled(xTargetsPerBlock, 'X'),
        for (var i = xTargetsPerBlock; i < trialsPerBlock; i++)
          _xDistractors[random.nextInt(_xDistractors.length)],
      ];
      _shuffle(letters, random);
      final trials = <ContinuousAttentionStimulus>[];
      for (final letter in letters) {
        trials.add(
          ContinuousAttentionStimulus(
            previousLetter: previous,
            currentLetter: letter,
            isTarget: letter == 'X',
          ),
        );
        previous = letter;
      }
      blocks.add(
        ContinuousAttentionBlockSequence(
          phase: phase,
          blockIndex: blockIndex,
          trials: trials,
        ),
      );
    }
    return previous;
  }

  static String? _appendAxBlocks({
    required List<ContinuousAttentionBlockSequence> blocks,
    required ContinuousAttentionRandom random,
    required ContinuousAttentionPhase phase,
    required int count,
    required String? previousLetter,
  }) {
    var previous = previousLetter;
    for (var blockIndex = 1; blockIndex <= count; blockIndex++) {
      // Un token cible s'étend en A puis X. Un distracteur s'étend en une
      // lettre : 6 × 2 + 19 = 31 stimuli exactement.
      final tokens = <bool>[
        ...List.filled(axTargetsPerBlock, true),
        ...List.filled(trialsPerBlock - (2 * axTargetsPerBlock), false),
      ];
      _shuffle(tokens, random);

      final trials = <ContinuousAttentionStimulus>[];
      for (final isAxPair in tokens) {
        if (isAxPair) {
          trials.add(
            ContinuousAttentionStimulus(
              previousLetter: previous,
              currentLetter: 'A',
              isTarget: false,
            ),
          );
          previous = 'A';
          trials.add(
            ContinuousAttentionStimulus(
              previousLetter: previous,
              currentLetter: 'X',
              isTarget: true,
            ),
          );
          previous = 'X';
          continue;
        }

        var letter = _alphabet[random.nextInt(_alphabet.length)];
        while (previous == 'A' && letter == 'X') {
          letter = _alphabet[random.nextInt(_alphabet.length)];
        }
        final isTarget = previous == 'A' && letter == 'X';
        trials.add(
          ContinuousAttentionStimulus(
            previousLetter: previous,
            currentLetter: letter,
            isTarget: isTarget,
          ),
        );
        previous = letter;
      }
      blocks.add(
        ContinuousAttentionBlockSequence(
          phase: phase,
          blockIndex: blockIndex,
          trials: trials,
        ),
      );
    }
    return previous;
  }

  static void _shuffle<T>(List<T> values, ContinuousAttentionRandom random) {
    for (var index = values.length - 1; index > 0; index--) {
      final swapIndex = random.nextInt(index + 1);
      final value = values[index];
      values[index] = values[swapIndex];
      values[swapIndex] = value;
    }
  }

  /// FNV-1a 32 bits sur les octets UTF-8, avec arithmétique non signée.
  static int fnv1a32(String value) {
    var hash = 0x811C9DC5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}

class ContinuousAttentionBlockSequence {
  ContinuousAttentionBlockSequence({
    required this.phase,
    required this.blockIndex,
    required List<ContinuousAttentionStimulus> trials,
  }) : trials = List.unmodifiable(trials);

  final ContinuousAttentionPhase phase;
  final int blockIndex;
  final List<ContinuousAttentionStimulus> trials;

  int get targetCount => trials.where((trial) => trial.isTarget).length;
}

class ContinuousAttentionStimulus {
  const ContinuousAttentionStimulus({
    required this.previousLetter,
    required this.currentLetter,
    required this.isTarget,
  });

  final String? previousLetter;
  final String currentLetter;
  final bool isTarget;
}

/// PRNG xorshift32 identique au générateur serveur.
class ContinuousAttentionRandom {
  ContinuousAttentionRandom(int seed)
    : _state = seed == 0 ? _nonZeroFallback : seed & 0xFFFFFFFF;

  // PROVISOIRE — doit rester identique au fallback backend. Cette valeur ne
  // s'applique que si le hash FNV-1a vaut exactement zéro.
  static const _nonZeroFallback = 0x6D2B79F5;

  int _state;

  int nextInt(int upperBound) {
    if (upperBound <= 0) {
      throw ArgumentError.value(upperBound, 'upperBound', 'must be positive');
    }
    var value = _state;
    value ^= (value << 13) & 0xFFFFFFFF;
    value ^= value >>> 17;
    value ^= (value << 5) & 0xFFFFFFFF;
    _state = value & 0xFFFFFFFF;
    return _state % upperBound;
  }
}
