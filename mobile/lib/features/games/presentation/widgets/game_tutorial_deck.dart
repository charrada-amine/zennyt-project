import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'game_system_components.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Une seule idée par carte ; l'illustration peut réutiliser les objets du jeu.
class GameTutorialStep {
  const GameTutorialStep({
    required this.title,
    required this.description,
    required this.illustration,
    required this.illustrationLabel,
    this.illustrationInteractive = false,
  });

  final String title;
  final String description;
  final Widget illustration;
  final String illustrationLabel;
  final bool illustrationInteractive;
}

/// Pile de cartes illustrées, parcourue par balayage ou par boutons.
/// Les contrôles restent en dehors du contenu défilant de la carte.
class GameTutorialDeck extends StatefulWidget {
  const GameTutorialDeck({
    super.key,
    required this.steps,
    required this.leading,
    required this.onComplete,
    this.completionLabel = 'Je suis prêt',
    this.showHeader = true,
  }) : assert(steps.length > 0);

  final List<GameTutorialStep> steps;
  final Widget leading;
  final VoidCallback onComplete;
  final String completionLabel;

  /// Masqué lorsque le jeu fournit déjà un en-tête persistant.
  final bool showHeader;

  @override
  State<GameTutorialDeck> createState() => _GameTutorialDeckState();
}

class _GameTutorialDeckState extends State<GameTutorialDeck> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == widget.steps.length - 1;
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeader) ...[
              Row(
                children: [
                  widget.leading,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Comment jouer',
                      style: AppTypography.titleMedium.copyWith(
                        color: ZennytGamePalette.blue,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Semantics(
              liveRegion: true,
              child: Text(
                'Étape ${_page + 1} sur ${widget.steps.length}',
                key: const ValueKey('game-tutorial-progress'),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: ZennytGamePalette.blue,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 540,
                    maxWidth: 500,
                  ),
                  child: Stack(
                    children: [
                      // Cartes arrière décoratives : aucune règle cachée annoncée.
                      if (!last)
                        Positioned.fill(
                          key: const ValueKey('game-tutorial-back'),
                          top: 16,
                          left: 16,
                          right: 16,
                          child: const ExcludeSemantics(
                            child: IgnorePointer(
                              child: GamePanel(
                                backgroundColor: ZennytGamePalette.mist,
                                child: SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      if (_page < widget.steps.length - 2)
                        Positioned.fill(
                          key: const ValueKey('game-tutorial-middle'),
                          top: 8,
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: const ExcludeSemantics(
                            child: IgnorePointer(
                              child: GamePanel(
                                backgroundColor: ZennytGamePalette.gamePanel,
                                child: SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        key: const ValueKey('game-tutorial-front'),
                        bottom: 16,
                        child: PageView.builder(
                          key: const ValueKey('game-tutorial-pages'),
                          controller: _controller,
                          itemCount: widget.steps.length,
                          onPageChanged: (page) => setState(() => _page = page),
                          itemBuilder: (context, index) => _TutorialCard(
                            key: ValueKey('game-tutorial-card-$index'),
                            step: widget.steps[index],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.steps.length,
                (index) => ExcludeSemantics(
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _page ? 26 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? ZennytGamePalette.magenta
                          : ZennytGamePalette.border,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (_page > 0) ...[
                  SizedBox(
                    width: 52,
                    child: IconButton.outlined(
                      tooltip: 'Carte précédente',
                      onPressed: () => _goTo(_page - 1),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        foregroundColor: ZennytGamePalette.blue,
                        side: BorderSide(color: ZennytGamePalette.border),
                      ),
                      icon: const AppIcon(HugeIcons.strokeRoundedArrowLeft01),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: GamePrimaryButton(
                    key: const ValueKey('game-tutorial-next'),
                    label: last ? widget.completionLabel : 'Suivant',
                    onPressed: last
                        ? widget.onComplete
                        : () => _goTo(_page + 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({super.key, required this.step});
  final GameTutorialStep step;

  @override
  Widget build(BuildContext context) => GamePanel(
    padding: EdgeInsets.zero,
    backgroundColor: Colors.white,
    borderColor: ZennytGamePalette.border,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: step.illustrationLabel,
                excludeSemantics: !step.illustrationInteractive,
                // Une illustration interactive peut annoncer son propre geste.
                child: Container(
                  height: (constraints.maxHeight * .6).clamp(240.0, 310.0),
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ZennytGamePalette.mist,
                        ZennytGamePalette.gamePanel.withValues(alpha: .14),
                      ],
                    ),
                  ),
                  child: step.illustration,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: ZennytGamePalette.blue,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      step.description,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: ZennytGamePalette.blue,
                        height: 1.4,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
