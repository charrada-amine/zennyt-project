import '../service/deterministic_random.dart';
import 'ist_provisional_rules.dart';

enum IstPhase {
  practice('PRACTICE'),
  test('TEST');

  const IstPhase(this.wire);
  final String wire;
}

/// Gain fixe (échantillonner est gratuit) ou décroissant (chaque case coûte).
enum IstCondition {
  fixedWin('FIXED_WIN'),
  decreasingWin('DECREASING_WIN');

  const IstCondition(this.wire);
  final String wire;
}

enum IstColor {
  blue('BLUE'),
  orange('ORANGE');

  const IstColor(this.wire);
  final String wire;

  IstColor get other => this == blue ? orange : blue;
}

class IstTrialSlot {
  const IstTrialSlot(this.trialIndex, this.phase, this.condition);
  final int trialIndex;
  final IstPhase phase;
  final IstCondition condition;
}

/// Grille générée d'un essai.
class IstLayout {
  const IstLayout({
    required this.slot,
    required this.boxes,
    required this.blueCount,
    required this.majorityColor,
  });

  final IstTrialSlot slot;
  final List<IstColor> boxes;
  final int blueCount;
  final IstColor majorityColor;
}

/// Configuration MOTEUR de l'IST — Clark, Robbins, Ersche & Sahakian (2006).
///
/// PARITÉ MOCK ⇄ BACKEND : miroir de `IstConfig.java` et de
/// `IstLayoutGenerator.java` (ordre exact des tirages).
class IstConfig {
  IstConfig._();

  static const protocolVersion = 'IST_CLARK_V1';
  static const gridSide = 5;
  static const boxCount = gridSide * gridSide;
  static const majorityThreshold = boxCount ~/ 2 + 1;
  static const testTrialsPerCondition = 10;
  static const fixedWinPoints = 100;
  static const decreasingWinStartPoints = 250;
  static const decreasingWinCostPerBox = 10;
  static const incorrectPenaltyPoints = 100;

  /// Entraînement FW, entraînement DW, 10 FW, 10 DW.
  static final List<IstTrialSlot> trialOrder = List.unmodifiable([
    const IstTrialSlot(0, IstPhase.practice, IstCondition.fixedWin),
    const IstTrialSlot(1, IstPhase.practice, IstCondition.decreasingWin),
    for (var i = 0; i < testTrialsPerCondition; i++)
      IstTrialSlot(2 + i, IstPhase.test, IstCondition.fixedWin),
    for (var i = 0; i < testTrialsPerCondition; i++)
      IstTrialSlot(2 + testTrialsPerCondition + i, IstPhase.test, IstCondition.decreasingWin),
  ]);

  static int get totalTrialCount => trialOrder.length;

  static int trialPoints(IstCondition condition, int boxesOpened, bool correct) {
    if (!correct) return -incorrectPenaltyPoints;
    return switch (condition) {
      IstCondition.fixedWin => fixedWinPoints,
      IstCondition.decreasingWin =>
        (decreasingWinStartPoints - decreasingWinCostPerBox * boxesOpened)
            .clamp(0, decreasingWinStartPoints)
            .toInt(),
    };
  }

  /// Gain encore possible pendant l'essai (affiché dans le HUD).
  static int possibleWin(IstCondition condition, int boxesOpened) =>
      trialPoints(condition, boxesOpened, true);

  static List<IstLayout> generateLayouts(String sessionId) {
    final random = DeterministicRandom.forSession(sessionId, protocolVersion);
    final support =
        IstProvisionalRules.blueCountMax - IstProvisionalRules.blueCountMin + 1;
    return List.unmodifiable([
      for (final slot in trialOrder) _layout(slot, random, support),
    ]);
  }

  static IstLayout _layout(IstTrialSlot slot, DeterministicRandom random, int support) {
    final blueCount = IstProvisionalRules.blueCountMin + random.nextInt(support);
    final cells = List<int>.generate(boxCount, (i) => i);
    random.shuffle(cells);
    final boxes = List<IstColor>.filled(boxCount, IstColor.orange);
    for (var i = 0; i < blueCount; i++) {
      boxes[cells[i]] = IstColor.blue;
    }
    return IstLayout(
      slot: slot,
      boxes: List.unmodifiable(boxes),
      blueCount: blueCount,
      majorityColor: blueCount >= majorityThreshold ? IstColor.blue : IstColor.orange,
    );
  }
}
