import 'package:flutter/material.dart';

/// L'écran de consentement, affiché **avant** de rejoindre l'appel.
///
/// Il est bloquant à dessein. Aujourd'hui l'enregistrement d'un entretien démarre à
/// `onJoinChannelSuccess` sans que personne ait accepté quoi que ce soit — en France comme
/// en Tunisie, enregistrer sans accord expose l'entreprise, et le déséquilibre entre un
/// recruteur et un candidat n'arrange rien.
///
/// Trois choix de conception, repris du module de détection de fraude où ils ont été
/// éprouvés :
///
/// - **un clic actif est exigé à chaque entretien**, jamais un réglage mémorisé : un accord
///   donné une fois pour toutes n'est pas un accord éclairé ;
/// - **refuser est aussi visible qu'accepter** — un bouton de refus grisé ou minuscule
///   transformerait le consentement en formalité ;
/// - **le refus n'empêche pas l'entretien**, il empêche l'enregistrement. Personne ne doit
///   perdre un entretien pour avoir refusé.
class CallConsentGate extends StatelessWidget {
  final String Function()? dureeConservation;
  final VoidCallback onAccepte;
  final VoidCallback onRefuse;

  const CallConsentGate({
    super.key,
    required this.onAccepte,
    required this.onRefuse,
    this.dureeConservation,
  });

  @override
  Widget build(BuildContext context) {
    final duree = dureeConservation?.call() ?? '24 heures';
    final theme = Theme.of(context);

    return PopScope(
      // Rien ne doit permettre de contourner l'écran, pas même le bouton retour.
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.mic_none_rounded, color: Colors.white, size: 44),
                  const SizedBox(height: 20),
                  Text(
                    'Avant de commencer',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Cet entretien est enregistré et analysé automatiquement afin de "
                    "détecter les tentatives d'échange de coordonnées personnelles en "
                    "dehors de la plateforme.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Point("L'audio reste sur nos serveurs et est effacé sous $duree."),
                  const _Point(
                      "Aucune décision automatique n'est prise : seul un extrait, "
                      "anonymisé, peut être relu par une personne de l'équipe."),
                  const _Point(
                      "L'enregistrement ne démarre que si les deux participants acceptent."),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onAccepte,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("J'accepte l'enregistrement"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onRefuse,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Continuer sans enregistrement"),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Refuser ne vous pénalise pas : l'entretien se déroule normalement.",
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final String texte;
  const _Point(this.texte);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: Icon(Icons.circle, size: 5, color: Colors.white38),
          ),
          Expanded(
            child: Text(
              texte,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white60, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
