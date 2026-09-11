import 'package:flutter/material.dart';


/// Composants réutilisables d'« Emotional Radar ».
///
/// Contraintes portées ici (planche « Accessibility Compliance ») :
/// cibles ≥ 48×48 px espacées de 8 px, et **le sens n'est jamais porté par la
/// couleur seule** — chaque état sélectionné combine bordure + fond + coche +
/// libellé, et expose un `Semantics` explicite.

/// Palette dédiée au jeu (dérivée des planches Figma clair + sombre).
class EmotionalRadarPalette {
  EmotionalRadarPalette._();

  static const Color canvas = Color(0xFF4F46E5); // fond de gameplay
  static const Color ink = Color(0xFF1B1B4B);
  static const Color muted = Color(0xFF6B7A99);
  static const Color card = Colors.white;
  static const Color magenta = Color(0xFFD12E7D);
  static const Color selectBlue = Color(0xFF2563EB);
  static const Color selectTint = Color(0xFFEFF4FF);
  static const Color lockedTint = Color(0xFFEEF2F9);
  static const Color border = Color(0xFFE2E8F4);
  static const Color successBg = Color(0xFFEFF9F3);
  static const Color successFg = Color(0xFF16A34A);
  static const Color errorBg = Color(0xFFFDF3F3);
  static const Color errorFg = Color(0xFFC0392B);
}

/// Déroulé d'une scène, v2.
///
/// L'étape « nuance » a disparu : le référentiel Cowen & Keltner traite les 45
/// émotions individuellement au lieu de les dériver de quelques familles, il
/// n'y a donc plus de famille à préciser.
///
/// L'étape de justification écrite a elle aussi été retirée, à la demande du
/// client : le tutoriel ne doit annoncer que ce que le panneau demande
/// réellement, sous peine de faire chercher au joueur un champ absent.
const List<String> emotionalRadarSteps = [
  'Watch the scene.',
  'Pick the dominant emotion.',
  'Rate its intensity: low, moderate or intense.',
  'Validate — the level adapts to you.',
];
