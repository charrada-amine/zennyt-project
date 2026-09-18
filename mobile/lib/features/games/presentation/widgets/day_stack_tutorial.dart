import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'day_stack_badges.dart';
import 'game_system_components.dart';
import 'game_tutorial_deck.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

// PROVISOIRE — taille des exemples à valider sur appareil (décision 64).
const double _kDayStackTutorialEmoteSize = 112;

/// Exemples visuels tirés du restaurant : les mêmes contrôles valent partout.
/// Le nombre de manches est fourni par l'écran, sans nouvelle règle métier.
class DayStackTutorial extends StatelessWidget {
  const DayStackTutorial({
    super.key,
    required this.leading,
    required this.onComplete,
    required this.roundCount,
    this.reviewing = false,
  });

  final Widget leading;
  final VoidCallback onComplete;
  final int roundCount;
  final bool reviewing;

  @override
  Widget build(BuildContext context) => GameTutorialDeck(
    leading: leading,
    onComplete: onComplete,
    completionLabel: reviewing ? 'Reprendre la partie' : 'Je suis prêt',
    steps: [
      const GameTutorialStep(
        title: 'Maintiens, puis déplace',
        description:
            'Déplace une tâche pour changer son horaire. '
            'Un geste court fait défiler l’agenda.',
        illustration: _MoveDemo(),
        illustrationInteractive: true,
        illustrationLabel:
            'Maintenir la carte puis la déplacer dans le planning.',
      ),
      const GameTutorialStep(
        title: 'D’abord, puis ensuite',
        description:
            '« Après : X » : termine la tâche X avant de commencer celle-ci.',
        illustration: _DayStackDemo(kind: _DemoKind.dependency),
        illustrationLabel:
            'Réceptionner la livraison, puis faire l’inventaire.',
      ),
      const GameTutorialStep(
        title: 'Reste dans la plage',
        description: 'La tâche doit commencer et finir dans la plage indiquée.',
        illustration: _DayStackDemo(kind: _DemoKind.window),
        illustrationLabel:
            'Une livraison de 15 minutes placée entre 7h00 et 8h00.',
      ),
      const GameTutorialStep(
        title: 'Termine avant l’heure',
        description:
            '« Avant 11h45 » : la tâche doit être terminée avant cette heure.',
        illustration: _DayStackDemo(kind: _DemoKind.deadline),
        illustrationLabel:
            'La cuisson se termine à 11h30, avant l’échéance de 11h45.',
      ),
      const GameTutorialStep(
        title: 'Commence à l’heure pile',
        description:
            '« Pile » fixe le début, avec la tolérance indiquée. '
            'Une plage vide est du temps mort.',
        illustration: _DayStackDemo(kind: _DemoKind.anchor),
        illustrationLabel:
            'Temps mort de 11h45 à 12h00, puis service à 12h00 pile.',
      ),
      GameTutorialStep(
        title: 'À toi de valider',
        description:
            'Réorganise sans pénalité. Seul « Valider » évalue le planning. '
            'Le score arrive après $roundCount manches.',
        illustration: _DayStackDemo(
          kind: _DemoKind.validate,
          rounds: roundCount,
        ),
        illustrationLabel:
            'Valider chaque planning, puis obtenir le score après '
            '$roundCount manches.',
      ),
    ],
  );
}

enum _DemoKind { dependency, window, deadline, anchor, validate }

class _DayStackDemo extends StatelessWidget {
  const _DayStackDemo({required this.kind, this.rounds = 4});
  final _DemoKind kind;
  final int rounds;

  @override
  Widget build(BuildContext context) => _SceneFrame(
    child: switch (kind) {
      _DemoKind.dependency => const Row(
        children: [
          Expanded(
            child: _DemoTask(
              taskId: 'reception_livraison',
              title: 'Livraison',
              detail: 'D’abord',
              emoteSize: 88,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: AppIcon(
              HugeIcons.strokeRoundedArrowRight02,
              color: ZennytGamePalette.magenta,
              size: 24,
            ),
          ),
          Expanded(
            child: _DemoTask(
              taskId: 'inventaire_stock',
              title: 'Inventaire',
              detail: 'Après : Livraison',
              emoteSize: 88,
            ),
          ),
        ],
      ),
      _DemoKind.window => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DemoMarker(label: '07h00 – 08h00'),
          SizedBox(height: 8),
          _DemoTask(
            taskId: 'reception_livraison',
            title: 'Livraison',
            detail: '07h15 – 07h30 · 15 min',
          ),
        ],
      ),
      _DemoKind.deadline => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DemoTask(
            taskId: 'cuisson',
            title: 'Cuire les plats',
            detail: 'Terminé à 11h30',
          ),
          SizedBox(height: 8),
          _DemoMarker(label: 'Avant 11h45'),
        ],
      ),
      _DemoKind.anchor => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DemoMarker(label: '11h45 – 12h00 · temps mort'),
          SizedBox(height: 8),
          _DemoTask(
            taskId: 'service',
            title: 'Servir',
            detail: '12h00 pile (±5 min)',
          ),
        ],
      ),
      _DemoKind.validate => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const DayStackTaskBadge(
                category: null,
                icon: null,
                universeId: 'restaurant',
                taskId: 'dressage_assiettes',
                emoteSize: 132,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: const AppIcon(
                    HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: ZennytGamePalette.success,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _DemoMarker(label: 'Valider'),
          const SizedBox(height: 12),
          Text(
            '$rounds manches · score',
            style: const TextStyle(
              color: ZennytGamePalette.blue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    },
  );
}

/// Seul le schéma s'adapte à sa zone ; l'explication garde sa taille accessible.
class _SceneFrame extends StatelessWidget {
  const _SceneFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: constraints.maxWidth,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: child,
          ),
        ),
      ),
    ),
  );
}

class _MoveDemo extends StatefulWidget {
  const _MoveDemo();

  @override
  State<_MoveDemo> createState() => _MoveDemoState();
}

class _MoveDemoState extends State<_MoveDemo> {
  bool _moved = false;
  bool _dragging = false;

  void _tryMove() => setState(() => _moved = !_moved);

  Widget _task() => const _DemoTask(
    taskId: 'reception_livraison',
    title: 'Livraison',
    detail: '15 min',
    horizontal: true,
    emoteSize: 80,
  );

  Widget _slot(int index) => DragTarget<int>(
    onWillAcceptWithDetails: (details) => details.data != index,
    onAcceptWithDetails: (_) => setState(() => _moved = index == 1),
    builder: (context, candidates, rejected) {
      final occupied = (_moved ? 1 : 0) == index;
      if (occupied) {
        return Semantics(
          button: true,
          label: 'Essayer le déplacement de la livraison',
          onTap: _tryMove,
          child: LongPressDraggable<int>(
            data: index,
            onDragStarted: () => setState(() => _dragging = true),
            onDragEnd: (_) => setState(() => _dragging = false),
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 260,
                child: Transform.rotate(angle: -.05, child: _task()),
              ),
            ),
            childWhenDragging: Opacity(opacity: .25, child: _task()),
            child: GestureDetector(
              onTap: _tryMove,
              child: Transform.rotate(
                angle: _moved ? .025 : -.025,
                child: _task(),
              ),
            ),
          ),
        );
      }
      return ExcludeSemantics(
        child: GamePanel(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          backgroundColor: candidates.isNotEmpty
              ? ZennytGamePalette.success.withValues(alpha: .12)
              : Colors.white.withValues(alpha: .5),
          borderColor: ZennytGamePalette.gamePanel.withValues(alpha: .3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                HugeIcons.strokeRoundedArrowDown02,
                color: candidates.isNotEmpty
                    ? ZennytGamePalette.success
                    : ZennytGamePalette.gameBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Dépose ici',
                  style: TextStyle(
                    color: ZennytGamePalette.blue,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => _SceneFrame(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _slot(0),
        const SizedBox(height: 12),
        _slot(1),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                _moved ? HugeIcons.strokeRoundedCheckmarkCircle02 : HugeIcons.strokeRoundedTouch01,
                color: _moved
                    ? ZennytGamePalette.success
                    : ZennytGamePalette.magenta,
                size: 22,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _moved
                      ? 'Bien joué !'
                      : _dragging
                      ? 'Glisse vers la place libre'
                      : 'Essaie avec ton doigt',
                  style: const TextStyle(
                    color: ZennytGamePalette.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DemoTask extends StatelessWidget {
  const _DemoTask({
    required this.taskId,
    required this.title,
    required this.detail,
    this.horizontal = false,
    this.emoteSize = _kDayStackTutorialEmoteSize,
  });
  final String taskId;
  final String title;
  final String detail;
  final bool horizontal;
  final double emoteSize;

  @override
  Widget build(BuildContext context) {
    final image = DayStackTaskBadge(
      category: null,
      icon: null,
      universeId: 'restaurant',
      taskId: taskId,
      emoteSize: emoteSize,
    );
    final caption = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: horizontal ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            color: ZennytGamePalette.blue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          textAlign: horizontal ? TextAlign.start : TextAlign.center,
          style: const TextStyle(color: ZennytGamePalette.blue, fontSize: 13),
        ),
      ],
    );
    return GamePanel(
      padding: const EdgeInsets.all(10),
      backgroundColor: Colors.white,
      borderColor: ZennytGamePalette.gamePanel.withValues(alpha: .16),
      child: horizontal
          ? Row(
              children: [
                image,
                const SizedBox(width: 8),
                Expanded(child: caption),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [image, const SizedBox(height: 4), caption],
            ),
    );
  }
}

class _DemoMarker extends StatelessWidget {
  const _DemoMarker({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: ZennytGamePalette.gameBlue.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: ZennytGamePalette.gameBlue,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
