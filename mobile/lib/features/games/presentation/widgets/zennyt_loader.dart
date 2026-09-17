import 'package:flutter/material.dart';

/// Logo de l'application, utilisé par l'animation de chargement.
const String kZennytLogoAsset = 'assets/images/Logo.png';

/// Animation de chargement Zennyt : le logo lui-même tourne.
///
/// Le logo est déjà une flèche circulaire ; c'est lui qui porte le mouvement,
/// sans anneau ni roue ajoutés autour. Chaque tour accélère puis ralentit, ce
/// qui donne à la flèche un élan plutôt qu'une rotation mécanique.
///
/// Sur un fond sombre (le mauve du plateau), le logo est posé sur une pastille
/// blanche immobile : ses teintes violettes s'y fondraient sinon.
///
/// Si le système demande de réduire les animations, le logo reste immobile :
/// l'écran annonce toujours le chargement, sans mouvement.
class ZennytLoader extends StatefulWidget {
  const ZennytLoader({
    super.key,
    this.size = 96,
    this.semanticsLabel,
    this.onDark = false,
  });

  /// Taille du logo (ou de sa pastille sur fond sombre).
  final double size;

  final String? semanticsLabel;

  /// Ajoute la pastille blanche immobile derrière le logo.
  final bool onDark;

  @override
  State<ZennytLoader> createState() => _ZennytLoaderState();
}

class _ZennytLoaderState extends State<ZennytLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  /// Centre de la flèche circulaire dans l'image (1024 × 916) : l'image n'est
  /// pas carrée et la pointe dépasse à droite, tourner autour du centre de
  /// l'image ferait vaciller le logo.
  static const Alignment _pivot = Alignment(-0.033, 0.0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final logoSize = widget.onDark ? size * 0.66 : size;
    final logo = RotationTransition(
      turns: CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      alignment: _pivot,
      child: Image.asset(
        kZennytLogoAsset,
        width: logoSize,
        height: logoSize,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        // Sans l'asset (tests, build incomplet), rien ne casse.
        errorBuilder: (_, _, _) => SizedBox.square(dimension: logoSize),
      ),
    );
    return Semantics(
      label: widget.semanticsLabel ?? 'Chargement',
      liveRegion: true,
      child: SizedBox.square(
        dimension: size,
        child: widget.onDark
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33071333),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(child: logo),
              )
            : Center(child: logo),
      ),
    );
  }
}

/// Écran de chargement centré : l'animation Zennyt et, si fourni, un libellé.
class ZennytLoadingView extends StatelessWidget {
  const ZennytLoadingView({
    super.key,
    this.label,
    this.onDark = false,
    this.size = 96,
  });

  final String? label;

  /// Libellé blanc, pour les fonds mauves du plateau.
  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZennytLoader(size: size, semanticsLabel: label, onDark: onDark),
            if (label != null) ...[
              const SizedBox(height: 22),
              Text(
                label!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onDark ? Colors.white : const Color(0xFF1B1B4B),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
