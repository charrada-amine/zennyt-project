import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';

const Color kMemoryPromptColor = Color(0xFF4ADE80);

/// Consigne de manche, qui cligne une fois à son arrivée.
///
/// Retour client : « on peut le faire clignoter une seule fois, c'est-à-dire
/// disparaître et réapparaître, pour attirer l'attention ». Une fois, et une
/// seule : un clignotement qui se répète devient un décor qu'on cesse de voir,
/// et il tomberait ici en pleine mémorisation — le moment où le joueur a le
/// plus besoin de calme.
///
/// Le clignotement se rejoue à CHAQUE nouvelle consigne, pas à chaque montage :
/// les phases d'observation et de manipulation partagent la même vue, et c'est
/// le passage de l'une à l'autre qui doit se remarquer.
class MemoryPrompt extends StatefulWidget {
  const MemoryPrompt(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
  });

  final String text;

  /// Variante compacte pour les consignes des autres jeux, sans changer l'effet.
  final TextStyle? style;
  final TextAlign textAlign;

  /// Durée d'un clignotement complet — effacement, silence, retour.
  ///
  /// Assez court pour ne pas retarder la lecture, assez long pour qu'un
  /// clignement d'œil ne le manque pas.
  static const Duration blinkDuration = Duration(milliseconds: 460);

  @override
  State<MemoryPrompt> createState() => _MemoryPromptState();
}

class _MemoryPromptState extends State<MemoryPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MemoryPrompt.blinkDuration,
    );
    // Sortie franche, absence brève, retour un peu plus lent : c'est le RETOUR
    // qu'on regarde. L'inverse — disparition lente — se lirait comme un bug
    // d'affichage plutôt que comme un appel.
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 34,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 16),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void didUpdateWidget(MemoryPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = Text(
      widget.text,
      textAlign: widget.textAlign,
      style: (widget.style ?? AppTypography.titleLarge).copyWith(
        color: kMemoryPromptColor,
        letterSpacing: 0,
      ),
    );
    // Animations coupées : la consigne se pose, pleine. Un joueur qui a demandé
    // moins de mouvement ne doit pas voir son texte s'effacer.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return label;
    return FadeTransition(opacity: _opacity, child: label);
  }
}
