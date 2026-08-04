import 'package:flutter/material.dart';

/// Design tokens centralisés — la SEULE source de vérité visuelle.
///
/// Géré par le Référent Design System. Les features ne définissent jamais
/// leurs propres couleurs/espacements : elles consomment ce thème.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0D9488);
  static const Color navy = Color(0xFF1A2B4A);
  static const Color surface = Color(0xFFF1F5F9);

  // Identité de marque "Progress Careers" (logo + accents du fil d'actualité).
  static const Color brandBlue = Color(0xFF2E48C8); // "PROGRESS" + onglet actif
  static const Color brandPink = Color(0xFFE6447D); // "Careers" + bouton chat
  static const Color link = Color(0xFF2563EB);       // liens cliquables
  static const Color muted = Color(0xFF8A90A6);      // textes secondaires
  static const Color hairline = Color(0xFFECECEF);   // séparateurs fins

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
