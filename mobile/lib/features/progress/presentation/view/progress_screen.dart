import 'package:flutter/material.dart';

import '../../../games/presentation/view/games_hub_screen.dart';

/// Onglet « Progrès » : héberge le hub des jeux sérieux cognitifs (Planifik,
/// Memory Quest, Choix&Cap). Point d'entrée de la feature games depuis la
/// barre de navigation.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GamesHubScreen();
  }
}
