import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/games_mock_repository.dart';
import 'package:zennyt/features/games/domain/config/emotional_radar_v2_config.dart';
import 'package:zennyt/features/games/domain/entities/emotional_radar_v2.dart';
import 'package:zennyt/features/games/presentation/games_providers.dart';
import 'package:zennyt/features/games/presentation/widgets/emotional_radar_video.dart';
import 'package:zennyt/features/games/presentation/view/emotional_radar_v2_gameplay.dart';
import 'package:zennyt/features/games/presentation/view/emotional_radar_screen.dart';

/// « Radar émotionnel » — parcours v2, référentiel Cowen & Keltner (45 émotions).
///
/// Ces tests verrouillent ce que le client a explicitement demandé et que la
/// version précédente ne faisait pas :
///
/// - 6 propositions au niveau 1, 9 aux niveaux 3-4 (`choices_per_level`) ;
/// - plus d'étape « nuance » — l'émotion est choisie directement ;
/// - intensité à trois crans, Faible / Modérée / Intense ;
/// - justification écrite obligatoire ;
/// - **aucun texte ne révèle l'émotion à identifier**.
void main() {
  /// Horloge injectable du mock : sans elle, le budget de réponse de 8 s
  /// s'écoulerait au rythme du test et rendrait les scénarios instables.
  late int clockMs;

  Widget app() => ProviderScope(
    overrides: [
      gamesRepositoryProvider.overrideWithValue(
        GamesMockRepository(emotionalRadarV2ClockMs: () => clockMs),
      ),
    ],
    child: const MaterialApp(home: EmotionalRadarScreen()),
  );

  setUp(() => clockMs = 0);

  void useLargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Couverture → tutoriel → première scène.
  Future<void> startGame(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start tutorial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('niveau 1 : six propositions, trois par ligne', (tester) async {
    useLargeSurface(tester);
    await startGame(tester);

    expect(
      find.byType(RadarEmotionButton),
      findsNWidgets(EmotionalRadarV2Config.choicesForLevel(1)),
      reason: 'le référentiel fixe choices_per_level = 6 au niveau 1',
    );
    expect(EmotionalRadarV2Config.choicesForLevel(1), 6);
    expect(kRadarChoicesPerRow, 3, reason: 'grille de 3 boutons par ligne');

    // La grille tombe juste : 6 et 9 se répartissent tous deux en lignes de 3.
    for (final level in [1, 2, 3, 4]) {
      expect(
        EmotionalRadarV2Config.choicesForLevel(level) % kRadarChoicesPerRow,
        0,
        reason: 'niveau $level : la grille laisserait une ligne incomplète',
      );
    }
  });

  testWidgets('plus d\'étape « nuance » : l\'émotion se choisit directement', (
    tester,
  ) async {
    useLargeSurface(tester);
    await startGame(tester);

    // Le référentiel traite les 45 émotions individuellement au lieu de les
    // dériver de familles : il n'y a plus de famille, donc plus de nuance.
    expect(find.textContaining('nuance', findRichText: true), findsNothing);
    expect(find.textContaining('Nuance'), findsNothing);
    expect(find.byType(RadarIntensitySelector), findsOneWidget);
  });

  testWidgets('intensité à trois crans : Faible, Modérée, Intense', (
    tester,
  ) async {
    useLargeSurface(tester);
    await startGame(tester);

    for (final label in EmotionalRadarV2Config.intensityScale) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: 'l\'échelle du référentiel est Faible / Modérée / Intense',
      );
    }
    expect(EmotionalRadarV2Config.intensityScale.length, 3);
  });

  testWidgets('Valider s\'active sur émotion + intensité, sans rien écrire', (
    tester,
  ) async {
    useLargeSurface(tester);
    await startGame(tester);

    FilledButton validateButton() => tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Valider'),
        matching: find.byType(FilledButton),
      ),
    );

    expect(validateButton().onPressed, isNull, reason: 'rien de sélectionné');

    await tester.tap(find.byType(RadarEmotionButton).first);
    await tester.pump();
    expect(validateButton().onPressed, isNull, reason: 'intensité manquante');

    await tester.tap(find.text('Modérée'));
    await tester.pump();
    expect(
      validateButton().onPressed,
      isNotNull,
      reason: 'deux réponses suffisent depuis le retrait de la 3e question',
    );
    expect(EmotionalRadarV2Config.requireExplanation, isFalse);
  });

  testWidgets('le panneau ne demande plus de justification écrite', (
    tester,
  ) async {
    // La troisième question a été retirée à la demande du client. Un champ de
    // saisie résiduel, même facultatif, relancerait exactement ce qu'il ne veut
    // plus voir : c'est l'absence du champ qu'on vérifie, pas son caractère
    // optionnel.
    useLargeSurface(tester);
    await startGame(tester);

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('Pourquoi'), findsNothing);
  });

  testWidgets('aucun texte de la scène ne révèle l\'émotion à identifier', (
    tester,
  ) async {
    useLargeSurface(tester);
    await startGame(tester);

    // Consigne client : « Aucun texte ne doit révéler l'émotion à identifier ».
    // La scène 1 attend SADNESS — la première des émotions filmées avancées en
    // tête de session. La bonne réponse figure forcément parmi les
    // propositions ; ce qu'on vérifie, c'est qu'elle n'apparaît nulle part
    // AILLEURS : un énoncé, une légende ou une alternative textuelle qui la
    // nommerait donnerait la réponse.
    expect(find.text('Tristesse'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RadarEmotionButton),
        matching: find.text('Tristesse'),
      ),
      findsOneWidget,
      reason:
          'le seul « Tristesse » de l\'écran doit être un bouton de réponse',
    );
    for (final forbidden in ['Scène', 'Situation :', 'Description']) {
      expect(find.textContaining(forbidden), findsNothing);
    }
  });

  testWidgets('sans vidéo, un placeholder muet qui ne souffle rien', (
    tester,
  ) async {
    useLargeSurface(tester);
    // Montée directe : depuis que les émotions filmées ouvrent la session, il
    // faudrait jouer quatre manches pour atteindre une scène sans vidéo.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RadarSceneStage(
            scene: EmotionalRadarV2Scene(
              sceneOrder: 4,
              level: 1,
              choicesCount: 1,
              choices: const [
                EmotionalRadarV2Choice(
                  key: 'JOY',
                  labelFr: 'Joie',
                  labelEn: 'Joy',
                ),
              ],
              mediaStatus: 'PLACEHOLDER_PENDING',
              maxResponseTimeMs: EmotionalRadarV2Config.maxResponseTimeMs,
              remainingResponseTimeMs: EmotionalRadarV2Config.maxResponseTimeMs,
              impulsiveThresholdMs: EmotionalRadarV2Config.minImpulsiveTimeMs,
            ),
            remainingMs: EmotionalRadarV2Config.maxResponseTimeMs,
            onOpenFullscreen: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RadarMediaPlaceholder), findsOneWidget);
    expect(find.text('Vidéo en cours de production'), findsOneWidget);
    // Le placeholder n'annonce PAS le type de cadrage : celui-ci est une
    // propriété de l'émotion cible, l'afficher restreindrait les propositions.
    for (final leak in [
      'Faciale',
      'Corporelle',
      'Relationnelle',
      'Contextuelle',
    ]) {
      expect(find.text(leak), findsNothing);
    }
  });

  testWidgets('une scène avec vidéo joue le clip, pas le placeholder', (
    tester,
  ) async {
    useLargeSurface(tester);
    // Montée directe de la vue de scène : atteindre la scène 6 par le jeu
    // coûterait cinq manches complètes pour vérifier un aiguillage d'affichage.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RadarSceneStage(
            scene: EmotionalRadarV2Scene(
              sceneOrder: 6,
              level: 1,
              choicesCount: 1,
              choices: const [
                EmotionalRadarV2Choice(
                  key: 'SADNESS',
                  labelFr: 'Tristesse',
                  labelEn: 'Sadness',
                ),
              ],
              mediaStatus: 'READY',
              mediaUrl: 'assets/games_demo/emotional_radar/phone_call.mp4',
              maxResponseTimeMs: EmotionalRadarV2Config.maxResponseTimeMs,
              remainingResponseTimeMs: EmotionalRadarV2Config.maxResponseTimeMs,
              impulsiveThresholdMs: EmotionalRadarV2Config.minImpulsiveTimeMs,
            ),
            remainingMs: EmotionalRadarV2Config.maxResponseTimeMs,
            onOpenFullscreen: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RadarMediaPlaceholder), findsNothing);
    expect(find.byType(EmotionalRadarVideo), findsOneWidget);

    // Le lecteur empile la vidéo ET sa barre de contrôles — lecture, minutage,
    // plein écran. L'enfermer dans un cadre 16:9 fixe écrase cette barre, et un
    // test ne le voit pas : sans lecteur initialisé, le widget renvoie sa
    // branche de chargement, qui tient dans le cadre. On vérifie donc la
    // STRUCTURE, seule chose observable ici.
    expect(
      find.ancestor(
        of: find.byType(EmotionalRadarVideo),
        matching: find.byType(AspectRatio),
      ),
      findsNothing,
      reason:
          'le lecteur porte sa propre hauteur : rien ne doit la contraindre',
    );
    // Le placeholder, lui, n'a pas de taille propre et garde son cadre.
    expect(tester.takeException(), isNull);
  });

  testWidgets('le budget de 30 s couvre la durée des clips', (tester) async {
    // Le référentiel écrit 8 000 ms, mais il vise des stimuli de 5 à 8 s. Les
    // clips réels vont jusqu'à 12 s : avec 8 s, le joueur était hors délai
    // avant même d'avoir vu la scène en entier.
    expect(EmotionalRadarV2Config.maxResponseTimeMs, 30000);
    expect(
      EmotionalRadarV2Config.maxResponseTimeMs,
      greaterThan(12000),
      reason: 'le budget doit couvrir le visionnage PUIS la réponse',
    );
  });

  testWidgets('en paysage, la vidéo plein écran ne déborde pas', (
    tester,
  ) async {
    // Format paysage d'un iPhone : c'est là que la hauteur devient la
    // contrainte et qu'une vidéo 16:9 pleine largeur ne tiendrait pas.
    tester.view.physicalSize = const Size(956, 440);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: RadarFullscreenSceneView(
          scene: EmotionalRadarV2Scene(
            sceneOrder: 1,
            level: 1,
            choicesCount: 1,
            choices: const [
              EmotionalRadarV2Choice(
                key: 'SADNESS',
                labelFr: 'Tristesse',
                labelEn: 'Sadness',
              ),
            ],
            mediaStatus: 'READY',
            mediaUrl: 'assets/games_demo/emotional_radar/phone_call.mp4',
            maxResponseTimeMs: EmotionalRadarV2Config.maxResponseTimeMs,
            remainingResponseTimeMs: EmotionalRadarV2Config.maxResponseTimeMs,
            impulsiveThresholdMs: EmotionalRadarV2Config.minImpulsiveTimeMs,
          ),
          sceneNumber: 1,
          totalScenes: EmotionalRadarV2Config.totalScenes,
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.takeException(),
      isNull,
      reason: 'un débordement de mise en page lèverait ici',
    );
  });

  testWidgets('le plein écran est un vrai lecteur, pas une carte', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(956, 440);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: RadarFullscreenSceneView(
          scene: EmotionalRadarV2Scene(
            sceneOrder: 1,
            level: 1,
            choicesCount: 1,
            choices: const [
              EmotionalRadarV2Choice(
                key: 'SADNESS',
                labelFr: 'Tristesse',
                labelEn: 'Sadness',
              ),
            ],
            mediaStatus: 'READY',
            mediaUrl: 'assets/games_demo/emotional_radar/phone_call.mp4',
            maxResponseTimeMs: EmotionalRadarV2Config.maxResponseTimeMs,
            remainingResponseTimeMs: EmotionalRadarV2Config.maxResponseTimeMs,
            impulsiveThresholdMs: EmotionalRadarV2Config.minImpulsiveTimeMs,
          ),
          sceneNumber: 1,
          totalScenes: EmotionalRadarV2Config.totalScenes,
        ),
      ),
    );
    await tester.pump();

    // Le rendu de la vidéo n'est pas observable en test — sans lecteur
    // initialisé, le widget affiche sa branche de chargement. On verrouille
    // donc l'INTENTION : mode immersif, contrôles clairs, fond noir. C'est
    // exactement ce qui manquait quand la vidéo n'était qu'une vignette
    // entourée de marges indigo.
    final player = tester.widget<EmotionalRadarVideo>(
      find.byType(EmotionalRadarVideo),
    );
    expect(player.immersive, isTrue);
    expect(player.onDarkBackground, isTrue);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.black);

    // Sortie explicite : sans elle, le joueur reste coincé en paysage.
    expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);
  });

  testWidgets('la correction vient du serveur et révèle l\'attendu', (
    tester,
  ) async {
    useLargeSurface(tester);
    await startGame(tester);

    await tester.tap(find.byType(RadarEmotionButton).first);
    await tester.pump();
    await tester.tap(find.text('Intense'));
    await tester.pump();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.byType(RadarFeedbackCard), findsOneWidget);
    expect(find.text('Émotion attendue'), findsOneWidget);
    expect(find.text('Intensité attendue'), findsOneWidget);
    expect(find.text('Next scene'), findsOneWidget);
  });

  testWidgets('hors délai : la réponse reste exigée, la scène est manquée', (
    tester,
  ) async {
    useLargeSurface(tester);
    await startGame(tester);

    // Le budget serveur est dépassé. Le contrat exige toujours une émotion et
    // une intensité : l'écran ne doit donc PAS se verrouiller.
    clockMs = EmotionalRadarV2Config.maxResponseTimeMs + 1500;

    await tester.tap(find.byType(RadarEmotionButton).first);
    await tester.pump();
    await tester.tap(find.text('Faible'));
    await tester.pump();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('hors délai'),
      findsOneWidget,
      reason: 'le dépassement doit être annoncé, pas masqué',
    );
  });

  testWidgets('le rappel des règles ne mentionne plus la nuance', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start tutorial'));
    await tester.pumpAndSettle();

    expect(find.textContaining('30-second timer'), findsOneWidget);
    expect(find.textContaining('6 or 9 options'), findsOneWidget);
    expect(find.textContaining('Faible, Modérée or Intense'), findsOneWidget);
    expect(find.textContaining('answer anyway'), findsOneWidget);
    expect(find.textContaining('nuance'), findsNothing);
  });
}
