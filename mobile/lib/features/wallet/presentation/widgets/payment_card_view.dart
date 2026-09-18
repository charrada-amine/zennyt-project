import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zennyt/shared/icons/app_icons.dart';

import '../../domain/card_input.dart';

/// Carte bancaire dessinée comme une vraie carte : format ID-1 (85,6 × 54 mm),
/// puce, sans-contact, logo du réseau, numéro, titulaire et expiration.
///
/// [showBack] retourne la carte (bande magnétique, panneau de signature et
/// cryptogramme) — utilisé pendant la saisie du CVC.
class PaymentCardView extends StatelessWidget {
  const PaymentCardView({
    super.key,
    required this.brand,
    required this.number,
    required this.holder,
    required this.expiry,
    this.cvc = '',
    this.showBack = false,
  });

  /// Carte enregistrée : numéro masqué sauf les 4 derniers chiffres.
  factory PaymentCardView.saved({
    Key? key,
    required String brand,
    required String last4,
    required String holder,
    required String? expiry,
  }) {
    final cardBrand = CardBrand.fromServer(brand);
    final masked = cardBrand == CardBrand.amex
        ? '•••• •••••• •$last4'
        : '•••• •••• •••• $last4';
    return PaymentCardView(
      key: key,
      brand: cardBrand,
      number: masked,
      holder: holder,
      expiry: expiry ?? '••/••',
    );
  }

  final CardBrand brand;

  /// Numéro tel qu'affiché (déjà groupé) ; complété par des points s'il est partiel.
  final String number;
  final String holder;
  final String expiry;
  final String cvc;
  final bool showBack;

  /// Ratio d'une carte ID-1 (85,6 / 54).
  static const double aspectRatio = 1.586;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: showBack ? math.pi : 0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        builder: (context, angle, _) {
          final back = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: back
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _CardBack(brand: brand, cvc: cvc),
                  )
                : _CardFront(
                    brand: brand,
                    number: number,
                    holder: holder,
                    expiry: expiry,
                  ),
          );
        },
      ),
    );
  }
}

/// Dégradé et reflets propres à chaque réseau.
List<Color> _gradientFor(CardBrand brand) => switch (brand) {
      CardBrand.visa => const [Color(0xFF141B5C), Color(0xFF23338C), Color(0xFF3B5BD1)],
      CardBrand.mastercard => const [Color(0xFF121214), Color(0xFF2A2A30), Color(0xFF45454F)],
      CardBrand.amex => const [Color(0xFF0B5C76), Color(0xFF1E8BAA), Color(0xFF4FB6CF)],
      CardBrand.discover => const [Color(0xFF1F1F26), Color(0xFF3A3A44), Color(0xFFB9531F)],
      CardBrand.unknown => const [Color(0xFF11428D), Color(0xFF5B45D6), Color(0xFFD12E7D)],
    };

class _CardShell extends StatelessWidget {
  const _CardShell({required this.brand, required this.child});

  final CardBrand brand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = _gradientFor(brand);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors[1].withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Stack(
            children: [
              // Reflets : deux grands disques translucides, comme le guilloché d'une carte.
              Positioned(
                right: -60,
                top: -80,
                child: _Glow(size: 220, opacity: 0.10),
              ),
              Positioned(
                left: -90,
                bottom: -120,
                child: _Glow(size: 260, opacity: 0.07),
              ),
              Positioned.fill(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.brand,
    required this.number,
    required this.holder,
    required this.expiry,
  });

  final CardBrand brand;
  final String number;
  final String holder;
  final String expiry;

  /// Numéro complété par des points pour garder la forme d'une carte pendant la saisie.
  String get _paddedNumber {
    final placeholder = brand == CardBrand.amex ? '•••• •••••• •••••' : '•••• •••• •••• ••••';
    if (number.length >= placeholder.length) return number;
    return number + placeholder.substring(number.length);
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      brand: brand,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final label = TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: w * 0.028,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          );
          final value = TextStyle(
            color: Colors.white,
            fontSize: w * 0.042,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(w * 0.065, w * 0.06, w * 0.065, w * 0.055),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'zennyt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    _BrandMark(brand: brand, height: w * 0.085),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _Chip(width: w * 0.13),
                    SizedBox(width: w * 0.035),
                    AppIcon(
                      HugeIcons.strokeRoundedNfc,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: w * 0.07,
                    ),
                  ],
                ),
                SizedBox(height: w * 0.045),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _paddedNumber,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.068,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: const [
                        Shadow(color: Color(0x40000000), offset: Offset(0, 1), blurRadius: 2),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: w * 0.04),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CARD HOLDER', style: label),
                          const SizedBox(height: 2),
                          Text(
                            holder.trim().isEmpty ? 'YOUR NAME' : holder.trim().toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: value,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: w * 0.04),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EXPIRES', style: label),
                        const SizedBox(height: 2),
                        Text(
                          expiry.isEmpty ? 'MM/YY' : expiry,
                          style: value.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.brand, required this.cvc});

  final CardBrand brand;
  final String cvc;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      brand: brand,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final placeholder = '•' * brand.cvcLength;
          final shown = cvc.isEmpty ? placeholder : cvc.padRight(brand.cvcLength, '•');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: w * 0.08),
              Container(height: w * 0.14, color: const Color(0xFF111114)),
              SizedBox(height: w * 0.06),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.065),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: w * 0.1,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF4F4F6), Color(0xFFE3E3E8)],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: w * 0.1,
                      padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        shown,
                        style: TextStyle(
                          color: const Color(0xFF1E1A4D),
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.065, w * 0.02, w * 0.065, 0),
                child: Text(
                  'SECURITY CODE',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: w * 0.026,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.065, 0, w * 0.065, w * 0.055),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _BrandMark(brand: brand, height: w * 0.08),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Puce EMV dorée.
class _Chip extends StatelessWidget {
  const _Chip({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.76,
      child: CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final body = RRect.fromRectAndRadius(rect, Radius.circular(size.height * 0.18));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6E3A1), Color(0xFFD9B35A), Color(0xFFF1D98C)],
        ).createShader(rect),
    );
    final line = Paint()
      ..color = const Color(0xFF9C7A2E).withValues(alpha: 0.7)
      ..strokeWidth = size.height * 0.05
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas
      ..drawLine(Offset(0, h * 0.35), Offset(w * 0.32, h * 0.35), line)
      ..drawLine(Offset(0, h * 0.65), Offset(w * 0.32, h * 0.65), line)
      ..drawLine(Offset(w * 0.68, h * 0.35), Offset(w, h * 0.35), line)
      ..drawLine(Offset(w * 0.68, h * 0.65), Offset(w, h * 0.65), line)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.32, h * 0.2, w * 0.36, h * 0.6),
          Radius.circular(h * 0.1),
        ),
        line,
      );
  }

  @override
  bool shouldRepaint(_ChipPainter oldDelegate) => false;
}

/// Logo du réseau, dessiné (pas d'image) pour rester net à toute taille.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.brand, required this.height});

  final CardBrand brand;
  final double height;

  @override
  Widget build(BuildContext context) {
    return switch (brand) {
      CardBrand.visa => Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontSize: height * 0.8,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
            height: 1,
          ),
        ),
      CardBrand.mastercard => SizedBox(
          width: height * 1.6,
          height: height,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: _Dot(size: height, color: const Color(0xFFEB001B)),
              ),
              Positioned(
                right: 0,
                child: _Dot(size: height, color: const Color(0xFFF79E1B).withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
      CardBrand.amex => Container(
          padding: EdgeInsets.symmetric(horizontal: height * 0.25, vertical: height * 0.08),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1.4),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'AMEX',
            style: TextStyle(
              color: Colors.white,
              fontSize: height * 0.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              height: 1,
            ),
          ),
        ),
      CardBrand.discover => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DISC',
              style: TextStyle(
                color: Colors.white,
                fontSize: height * 0.5,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            _Dot(size: height * 0.5, color: const Color(0xFFF58220)),
            Text(
              'VER',
              style: TextStyle(
                color: Colors.white,
                fontSize: height * 0.5,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      CardBrand.unknown => AppIcon(
          HugeIcons.strokeRoundedCreditCard,
          color: Colors.white,
          size: height,
        ),
    };
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
