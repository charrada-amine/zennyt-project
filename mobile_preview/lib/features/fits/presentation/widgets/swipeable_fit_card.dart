import 'package:flutter/material.dart';

import '../../domain/entities/fit_item.dart';
import 'fit_card.dart';

/// Carte "Fits" déplaçable à la Tinder : on la fait glisser horizontalement,
/// elle pivote, affiche le tampon LIKE / NOPE, et déclenche le swipe quand on
/// dépasse le seuil (ou via les boutons d'action — voir [SwipeableFitCardState]).
class SwipeableFitCard extends StatefulWidget {
  final FitItem item;
  final VoidCallback onLike;
  final VoidCallback onNope;
  final VoidCallback? onTap;

  const SwipeableFitCard({
    super.key,
    required this.item,
    required this.onLike,
    required this.onNope,
    this.onTap,
  });

  @override
  SwipeableFitCardState createState() => SwipeableFitCardState();
}

class SwipeableFitCardState extends State<SwipeableFitCard>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  bool _flying = false;
  late final AnimationController _ctrl;
  Animation<double>? _anim;

  static const _threshold = 110.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250))
      ..addListener(() {
        if (_anim != null) setState(() => _dragX = _anim!.value);
      });
  }

  @override
  void didUpdateWidget(covariant SwipeableFitCard old) {
    super.didUpdateWidget(old);
    // Nouvel élément → on recentre la carte.
    if (old.item.id != widget.item.id) {
      _ctrl.stop();
      _anim = null;
      _flying = false;
      _dragX = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // API publique pour les boutons d'action :
  void swipeRight() => _flyOff(true);
  void swipeLeft() => _flyOff(false);

  void _flyOff(bool like) {
    if (_flying) return;
    _flying = true;
    final w = MediaQuery.of(context).size.width;
    _anim = Tween<double>(begin: _dragX, end: like ? w * 1.3 : -w * 1.3)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward(from: 0).whenComplete(() {
      _flying = false;
      if (like) {
        widget.onLike();
      } else {
        widget.onNope();
      }
    });
  }

  void _settle() {
    _anim = Tween<double>(begin: _dragX, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final angle = (_dragX / w) * 0.5;
    final likeOpacity = (_dragX / 120).clamp(0.0, 1.0);
    final nopeOpacity = (-_dragX / 120).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragUpdate: (d) {
        if (_flying) return;
        setState(() => _dragX += d.delta.dx);
      },
      onHorizontalDragEnd: (d) {
        if (_flying) return;
        final v = d.primaryVelocity ?? 0;
        if (_dragX > _threshold || v > 800) {
          _flyOff(true);
        } else if (_dragX < -_threshold || v < -800) {
          _flyOff(false);
        } else {
          _settle();
        }
      },
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            children: [
              Positioned.fill(child: FitCard(item: widget.item)),
              Positioned(
                top: 26,
                left: 22,
                child: Opacity(
                    opacity: nopeOpacity,
                    child: _stamp('NOPE', const Color(0xFFE53935), 0.25)),
              ),
              Positioned(
                top: 26,
                right: 22,
                child: Opacity(
                    opacity: likeOpacity,
                    child: _stamp('LIKE', const Color(0xFF22A06B), -0.25)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stamp(String text, Color color, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 22)),
      ),
    );
  }
}
