import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Couleurs des maquettes Fits (grille Fit Scores, carte de swipe), avec leur
/// pendant sombre.
class FitsPalette {
  const FitsPalette._({
    required this.dark,
    required this.title,
    required this.navy,
    required this.indigo,
    required this.chipBg,
    required this.chipText,
    required this.deckBg,
    required this.deckFade,
    required this.deckDivider,
    required this.segmentBg,
    required this.viewMoreBg,
    required this.fieldBorder,
  });

  final bool dark;
  final Color title;
  final Color navy;
  final Color indigo;
  final Color chipBg;
  final Color chipText;
  final Color deckBg;
  final Color deckFade;
  final Color deckDivider;
  final Color segmentBg;
  final Color viewMoreBg;
  final Color fieldBorder;

  static const magenta = Color(0xFFD12E7D);
  static const green = Color(0xFF22C55E);

  static FitsPalette of(BuildContext context) {
    final colors = context.colors;
    if (Theme.of(context).brightness == Brightness.dark) {
      return FitsPalette._(
        dark: true,
        title: colors.textDarkBlue,
        navy: const Color(0xFF8FA8E8),
        indigo: const Color(0xFF6D62F0),
        chipBg: const Color(0xFF2A2A31),
        chipText: const Color(0xFFB4B4C2),
        deckBg: const Color(0xFF22232B),
        deckFade: const Color(0xFF2F3B6E),
        deckDivider: const Color(0xFF363846),
        segmentBg: const Color(0xFF22232B),
        viewMoreBg: const Color(0xFF22232B),
        fieldBorder: const Color(0xFF3A3A44),
      );
    }
    return const FitsPalette._(
      dark: false,
      title: Color(0xFF14285A),
      navy: Color(0xFF1B3F8A),
      indigo: Color(0xFF5646E6),
      chipBg: Color(0xFFF0F1F4),
      chipText: Color(0xFF4B5563),
      deckBg: Color(0xFFF3F5FA),
      deckFade: Color(0xFFA9B8EC),
      deckDivider: Color(0xFFC9D0E0),
      segmentBg: Color(0xFFEAF0FA),
      viewMoreBg: Color(0xFFEEF0F4),
      fieldBorder: Color(0xFFC8CDD6),
    );
  }
}

/// « 1.2K - 2K /Mo » → (« 1.2K - 2K », « /Mo ») pour peindre le montant et la
/// période différemment, comme la maquette (« $15K/Mo »).
(String, String) splitSalary(String salary) {
  final i = salary.lastIndexOf(' /');
  if (i < 0) return (salary, '');
  return (salary.substring(0, i), salary.substring(i + 1));
}

/// « Developer · Senior » → « Developer | Senior », séparateur des maquettes.
String pipeJoined(String value) => value.replaceAll(' · ', ' | ');
