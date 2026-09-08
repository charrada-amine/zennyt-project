import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/audio/sound_service.dart';
import 'package:zennyt/features/games/presentation/widgets/game_system_components.dart';

/// Règles de pause du cahier des charges « Harmonisation des règles de pause et
/// de scoring » (§2-3).
///
/// Le menu pause contredisait la règle « une interruption annule la session » :
/// il s'ouvrait autant de fois qu'on voulait. La solution retenue n'est pas un
/// mode Entraînement / mode Test, mais une **fenêtre unique de 30 secondes**,
/// réservée aux réglages. Ces tests verrouillent ce mécanisme au niveau du
/// composant partagé, donc pour les onze jeux d'un coup.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GamePauseAllowance', () {
    final start = DateTime.utc(2026, 1, 1, 12);
    DateTime at(int seconds) => start.add(Duration(seconds: seconds));

    /// Retour de test client : « le menu pause n'est accessible qu'une seule
    /// fois ; après Resume ou View Rules, il ne doit plus rester disponible ».
    ///
    /// Une version intermédiaire faisait des 30 s un budget cumulatif,
    /// réouvrable tant qu'il en restait. C'est cette lecture-là qui a été
    /// refusée : les 30 s sont un PLAFOND, pas une réserve à dépenser.
    test('Resume éteint le droit, même après deux secondes de pause', () {
      final allowance = GamePauseAllowance();
      withClock(Clock.fixed(start), () {
        expect(allowance.canOpen, isTrue);
        expect(allowance.open(), kGamePauseWindow);
      });

      withClock(Clock.fixed(at(2)), () {
        allowance.close();
        expect(
          allowance.canOpen,
          isFalse,
          reason: 'une ouverture, et une seule, quelle qu\'en soit la durée',
        );
        expect(allowance.canReopen, isFalse);
        expect(allowance.remaining, Duration.zero);
        expect(allowance.affordance, GameMenuAffordance.exit);
      });

      // Deux minutes de jeu plus tard, toujours rien.
      withClock(Clock.fixed(at(130)), () {
        expect(allowance.canOpen, isFalse);
        expect(allowance.open(), Duration.zero);
      });
    });

    test('View Rules est un aller-retour, pas une seconde ouverture', () {
      final allowance = GamePauseAllowance();
      withClock(Clock.fixed(start), allowance.open);

      // 12 s plus tard, le joueur revient de l'écran de règles. `close()` n'a
      // pas été appelé : le jeu est toujours en pause.
      withClock(Clock.fixed(at(12)), () {
        expect(
          allowance.canReopen,
          isTrue,
          reason: 'le menu se réaffiche sur le temps restant de SON ouverture',
        );
        expect(
          allowance.remaining,
          const Duration(seconds: 18),
          reason:
              'le temps court pendant les règles : sans cela, y passer donnerait '
              'une pause sans fin',
        );
        // `open()` est idempotent : il ne relance pas le décompte.
        expect(allowance.open(), const Duration(seconds: 18));
      });

      // Puis Resume : le droit s'éteint.
      withClock(Clock.fixed(at(15)), () {
        allowance.close();
        expect(allowance.canOpen, isFalse);
        expect(allowance.canReopen, isFalse);
      });
    });

    test('les 30 s sont un plafond : passé le délai, plus rien', () {
      final allowance = GamePauseAllowance();
      withClock(Clock.fixed(start), allowance.open);

      withClock(Clock.fixed(at(31)), () {
        expect(allowance.remaining, Duration.zero);
        expect(allowance.canOpen, isFalse);
        expect(
          allowance.canReopen,
          isFalse,
          reason: 'même en restant dans le menu, on ne dépasse pas le plafond',
        );
        expect(
          allowance.affordance,
          GameMenuAffordance.exit,
          reason:
              'à zéro, le menu se referme seul, la partie repart et le bouton '
              'bascule sur la sortie',
        );
      });
    });

    test('une nouvelle partie rend le droit', () {
      final allowance = GamePauseAllowance();
      withClock(Clock.fixed(start), allowance.open);
      withClock(Clock.fixed(at(3)), allowance.close);
      expect(allowance.canOpen, isFalse);

      allowance.reset();
      expect(allowance.canOpen, isTrue);
      expect(allowance.remaining, kGamePauseWindow);
    });
  });

  group('GamePauseScaffold — compte à rebours', () {
    testWidgets('décompte les secondes puis notifie l\'expiration', (
      tester,
    ) async {
      var expired = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GamePauseScaffold(
              countdown: const Duration(seconds: 3),
              onCountdownExpired: () => expired++,
              buttons: [GamePrimaryButton(label: 'Resume', onPressed: () {})],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Menu closes in 3s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Menu closes in 2s'), findsOneWidget);
      expect(expired, 0);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(); // laisse passer le post-frame de l'expiration
      expect(find.text('Menu closes in 0s'), findsOneWidget);
      expect(expired, 1, reason: 'le menu se referme seul à zéro');

      // Le rappel ne doit jamais partir deux fois : il dépile une route.
      await tester.pump(const Duration(seconds: 5));
      expect(expired, 1);
    });

    /// Les dix dernières secondes étaient signalées en rouge et rien d'autre.
    /// Un candidat qui règle son volume, tête baissée dans le menu, ne voyait
    /// rien venir et se faisait renvoyer au jeu sans préavis.
    testWidgets('un tic sonore accompagne chacune des dix dernières secondes', (
      tester,
    ) async {
      final played = <GameSfx>[];
      SoundService.debugOnSfx = played.add;
      addTearDown(() => SoundService.debugOnSfx = null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GamePauseScaffold(
              countdown: const Duration(seconds: 14),
              onCountdownExpired: () {},
              buttons: [GamePrimaryButton(label: 'Resume', onPressed: () {})],
            ),
          ),
        ),
      );
      await tester.pump();

      // 14 → 11 : muet. On n'installe pas un tic sur toute la durée du menu,
      // seulement sur sa fin.
      await tester.pump(const Duration(seconds: 3));
      expect(
        played,
        isEmpty,
        reason: 'au-dessus de 10 s restantes, le menu ne fait aucun bruit',
      );

      // 11 → 0 : un tic à chaque seconde affichée de 10 à 1.
      await tester.pump(const Duration(seconds: 11));
      await tester.pump();
      expect(
        played,
        List.filled(10, GameSfx.timerDecrease),
        reason:
            'dix tics exactement, de « 10s » à « 1s ». Rien à zéro : le menu '
            's\'y referme et le jeu reprend la main avec ses propres sons',
      );
    });

    testWidgets('le tic respecte la coupure du son', (tester) async {
      final played = <GameSfx>[];
      SoundService.debugOnSfx = played.add;
      addTearDown(() {
        SoundService.debugOnSfx = null;
        SoundService.instance.setSfxEnabled(true);
      });
      SoundService.instance.setSfxEnabled(false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GamePauseScaffold(
              countdown: const Duration(seconds: 5),
              onCountdownExpired: () {},
              buttons: [GamePrimaryButton(label: 'Resume', onPressed: () {})],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(
        played,
        isEmpty,
        reason:
            'le réglage « Son » du menu pause coupe aussi le tic — il serait '
            'absurde qu\'un candidat qui vient de couper le son l\'entende',
      );
    });

    testWidgets('sans compte à rebours, le menu reste tel qu\'avant', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GamePauseScaffold(
              buttons: [GamePrimaryButton(label: 'Resume', onPressed: () {})],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Menu closes in'), findsNothing);
    });
  });

  group('GameHud', () {
    /// Ce test exigeait autrefois la DISPARITION du bouton une fois la fenêtre
    /// consommée. C'était la lecture littérale du cahier des charges, et elle
    /// enfermait le candidat : « Exit mission » vivait dans le menu de pause, et
    /// disparaissait avec lui. Il ne restait qu'à fermer l'application, ce que
    /// le jeu traite comme une interruption subie — tentative annulée, sans
    /// confirmation. Arbitrage du chef de projet : le bouton reste, il devient
    /// « Exit mission » et change d'icône.
    testWidgets('le bouton devient « Exit mission » une fois la fenêtre '
        'consommée', (tester) async {
      Future<void> pumpHud(GameMenuAffordance affordance) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameHud(
              score: 0,
              timeLabel: '10:00',
              progress: 1,
              onPause: () {},
              affordance: affordance,
            ),
          ),
        ),
      );

      await pumpHud(GameMenuAffordance.pause);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await pumpHud(GameMenuAffordance.exit);
      expect(
        find.byTooltip('Exit mission'),
        findsOneWidget,
        reason: 'sans ce bouton, plus aucune sortie volontaire n\'est offerte',
      );
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });

    test('l\'affordance bascule dès la première fermeture du menu', () {
      final start = DateTime.utc(2026, 1, 1, 12);
      final allowance = GamePauseAllowance();
      expect(allowance.affordance, GameMenuAffordance.pause);

      withClock(Clock.fixed(start), allowance.open);
      expect(
        allowance.affordance,
        GameMenuAffordance.exit,
        reason:
            'le droit est consommé dès l\'ouverture : le bouton ne peut plus '
            'proposer une seconde pause',
      );

      withClock(Clock.fixed(start.add(const Duration(seconds: 5))), () {
        allowance.close();
        expect(allowance.affordance, GameMenuAffordance.exit);
      });
    });
  });

  group('GameExitConfirmDialog', () {
    testWidgets('avertit que la tentative sera annulée et renvoie le choix', (
      tester,
    ) async {
      bool? answer;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    answer = await GameExitConfirmDialog.show(context),
                child: const Text('quit'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('quit'));
      await tester.pumpAndSettle();
      expect(find.text('Leave mission?'), findsOneWidget);
      expect(find.textContaining('no score will be recorded'), findsOneWidget);

      await tester.tap(find.text('Continue mission'));
      await tester.pumpAndSettle();
      expect(answer, isFalse, reason: 'on ne sort pas par accident');

      await tester.tap(find.text('quit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quit without saving'));
      await tester.pumpAndSettle();
      expect(answer, isTrue);
    });
  });
}
