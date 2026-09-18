part of 'games_hub_screen.dart';

/// Intro « Play & discover your talent », montrée à la première visite du hub.
class _GamesIntro extends StatefulWidget {
  const _GamesIntro({super.key, required this.onExplore, required this.onSkip});

  final VoidCallback onExplore;
  final VoidCallback onSkip;

  @override
  State<_GamesIntro> createState() => _GamesIntroState();
}

class _GamesIntroState extends State<_GamesIntro>
    with SingleTickerProviderStateMixin {
  /// Flottement des pastilles autour de l'illustration.
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 12, 0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onSkip,
                style: TextButton.styleFrom(foregroundColor: _hub(context).ink),
                child: Text(
                  'Plus tard',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: _hub(context).ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: _IntroHeadline(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    final panel = _IntroPanel(
      onExplore: widget.onExplore,
      onLearnMore: () => _showLearnMore(context),
    );
    final roomy = MediaQuery.sizeOf(context).height >= 680 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.3;

    return Scaffold(
      backgroundColor: _hub(context).surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_hub(context).heroTop, _hub(context).heroMid, _hub(context).heroBottom],
            stops: [0, 0.45, 0.75],
          ),
        ),
        // Écran assez haut : l'illustration prend la place restante. Sinon
        // (petit écran, grand texte) tout défile, illustration à taille fixe.
        child: roomy
            ? Column(
                children: [
                  top,
                  Expanded(child: _IntroHero(float: _float)),
                  panel,
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    top,
                    SizedBox(height: 250, child: _IntroHero(float: _float)),
                    panel,
                  ],
                ),
              ),
      ),
    );
  }
}

class _IntroHeadline extends StatelessWidget {
  const _IntroHeadline();

  @override
  Widget build(BuildContext context) {
    final headline = AppTypography.headlineLarge.copyWith(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      height: 1.08,
      letterSpacing: -1.2,
    );
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Joue et découvre\n',
                style: headline.copyWith(color: _hub(context).ink),
              ),
              TextSpan(
                text: 'ton talent',
                style: headline.copyWith(color: _hub(context).violet),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Des jeux courts. De vrais repères.\nLe meilleur de toi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hub(context).muted,
            fontFamily: AppTypography.fontFamily,
            fontSize: 16.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Illustration + pastilles flottantes (cerveau, idée, cible, puzzle) et bulle.
class _IntroHero extends StatelessWidget {
  const _IntroHero({required this.float});

  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = math.min(constraints.maxWidth, 430.0);
        // Recadrage : le haut du chignon jusqu'au bas du portable.
        final imageWidth = math.min(h * 1.12, w * 0.92);
        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: 0,
                  child: _FadedIllustration(width: imageWidth, height: h),
                ),
                _FloatingBubble(
                  float: float,
                  phase: 0,
                  alignment: const Alignment(-0.80, -0.78),
                  color: const Color(0xFFFFD9E8),
                  iconColor: const Color(0xFFE0559B),
                  icon: HugeIcons.strokeRoundedBrain02,
                  size: 62,
                  angle: -0.12,
                ),
                _FloatingBubble(
                  float: float,
                  phase: 0.3,
                  alignment: const Alignment(0.74, -0.95),
                  color: const Color(0xFFFFEDB0),
                  iconColor: const Color(0xFFDB9A00),
                  icon: HugeIcons.strokeRoundedIdea01,
                  size: 58,
                  angle: 0.1,
                ),
                _FloatingBubble(
                  float: float,
                  phase: 0.55,
                  alignment: const Alignment(-0.96, 0.18),
                  color: const Color(0xFFCDEFDB),
                  iconColor: const Color(0xFF22A06B),
                  icon: HugeIcons.strokeRoundedTarget02,
                  size: 58,
                  angle: -0.08,
                ),
                _FloatingBubble(
                  float: float,
                  phase: 0.8,
                  alignment: const Alignment(0.94, -0.28),
                  color: const Color(0xFFD7DEFF),
                  iconColor: const Color(0xFF4F6BED),
                  icon: HugeIcons.strokeRoundedPuzzle,
                  size: 56,
                  angle: 0.14,
                ),
                const Align(
                  alignment: Alignment(0.98, 0.52),
                  child: _SpeechBubble(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// L'illustration a un fond lavande uni : ses bords sont fondus dans le dégradé
/// de la page pour qu'aucun rectangle ne se voie.
class _FadedIllustration extends StatelessWidget {
  const _FadedIllustration({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    Shader edgeFade(Rect rect, {required bool vertical}) => LinearGradient(
          begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
          end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: const [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: vertical ? const [0, 0.18, 1, 1] : const [0, 0.14, 0.86, 1],
        ).createShader(rect);

    return ExcludeSemantics(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        // En sombre, le fond lavande de l'illustration ne se fond plus dans
        // la page : un masque radial n'en garde qu'un halo autour du dessin.
        shaderCallback: (rect) => _hub(context).isDark
            ? const RadialGradient(
                center: Alignment(0, 0.2),
                radius: 0.78,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.6, 1],
              ).createShader(rect)
            : edgeFade(rect, vertical: false),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => edgeFade(rect, vertical: true),
          child: SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              _introIllustration,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.1),
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  const _FloatingBubble({
    required this.float,
    required this.phase,
    required this.alignment,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.size,
    required this.angle,
  });

  final Animation<double> float;
  final double phase;
  final Alignment alignment;
  final Color color;
  final Color iconColor;
  final AppIconData icon;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final bubble = Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.34),
          border: Border.all(color: _hub(context).card.withValues(alpha: 0.8), width: 2),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: AppIcon(icon, color: iconColor, size: size * 0.5),
        ),
      ),
    );
    return Align(
      alignment: alignment,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: float,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              0,
              math.sin((float.value + phase) * math.pi * 2) * 5,
            ),
            child: child,
          ),
          child: bubble,
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: _hub(context).card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: _hub(context).violet.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        'Des jeux qui\nrévèlent tes\nforces',
        style: TextStyle(
          color: _hub(context).ink,
          fontFamily: AppTypography.fontFamily,
          fontSize: 12.5,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Panneau blanc du bas : trois atouts, bouton « Explore games », « Learn more ».
class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.onExplore, required this.onLearnMore});

  final VoidCallback onExplore;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, 26, 22, 12 + bottomInset),
      decoration: BoxDecoration(
        color: _hub(context).card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: _hub(context).violet.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _IntroPerk(
                  icon: HugeIcons.strokeRoundedClock01,
                  title: '10–13 min',
                  caption: 'par jeu',
                ),
              ),
              Expanded(
                child: _IntroPerk(
                  icon: HugeIcons.strokeRoundedChartLineData01,
                  title: 'Analyses',
                  caption: 'personnalisées',
                ),
              ),
              Expanded(
                child: _IntroPerk(
                  icon: HugeIcons.strokeRoundedAward01,
                  title: 'Suis ta',
                  caption: 'progression',
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _ExploreButton(onTap: onExplore),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onLearnMore,
            style: TextButton.styleFrom(foregroundColor: _hub(context).violet),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'En savoir plus',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                AppIcon(
                  HugeIcons.strokeRoundedArrowDown02,
                  color: _hub(context).violet,
                  size: 18
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPerk extends StatelessWidget {
  const _IntroPerk({
    required this.icon,
    required this.title,
    required this.caption,
  });

  final AppIconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppIcon(icon, color: _hub(context).violet, size: 28),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hub(context).ink,
            fontFamily: AppTypography.fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _hub(context).muted,
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ExploreButton extends StatelessWidget {
  const _ExploreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Découvrir les jeux',
      excludeSemantics: true,
      child: Material(
        color: _hub(context).cta,
        borderRadius: BorderRadius.circular(999),
        elevation: 10,
        shadowColor: _hub(context).cta.withValues(alpha: 0.35),
        child: InkWell(
          key: const ValueKey('games-intro-explore'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(56, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Découvrir les jeux',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _hub(context).onCta,
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: AppIcon(
                      HugeIcons.strokeRoundedArrowRight02,
                      color: Color(0xFF1E1A4D),
                      size: 22
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « Learn more » : les cinq dimensions et le déroulé, en une feuille.
Future<void> _showLearnMore(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: _hub(context).card,
    barrierColor: _hub(context).barrier,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: _hub(context).line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Comment ça marche',
              style: AppTypography.headlineLarge.copyWith(
                color: _hub(context).ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chaque jeu mesure une aptitude. Joue à ton rythme : chaque jeu '
              'terminé enrichit ton profil de talents.',
              style: TextStyle(
                color: _hub(context).muted,
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            for (final category in _categories) ...[
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _hub(context).tint(category),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(category.iconAsset, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title,
                          style: TextStyle(
                            color: _hub(context).ink,
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${category.tagline} · ${category.gamesLabel}',
                          style: _metaStyle(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: _hub(context).cta,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Compris',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
