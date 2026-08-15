import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

enum VirtualBgType { none, blur, image }

final isMutedProvider = StateProvider<bool>((ref) => false);
final isCameraOffProvider = StateProvider<bool>((ref) => true);
final isSpeakerOnProvider = StateProvider<bool>((ref) => false);
final isFrontCameraProvider = StateProvider<bool>((ref) => true);
final showAlertProvider = StateProvider<bool>((ref) => false);

/// Contrôle l'affichage du panneau de fond virtuel
final showVirtualBgPanelProvider = StateProvider<bool>((ref) => false);

/// Fond virtuel actuellement actif sur le flux local
final virtualBackgroundTypeProvider =
    StateProvider<VirtualBgType>((ref) => VirtualBgType.none);

/// --- NOUVEAUX PROVIDERS POUR LES COULEURS ET IMAGES ---


/// Liste des chemins d'images (à remplacer par vos assets réels)
final availableBgImages = [
  'assets/images/bg_office.png',
  'assets/images/bg_beach.png',
  'assets/images/bg_abstract.png',
  'assets/images/bg_room.png',
];


/// Index de l'image sélectionnée
final selectedImageIndexProvider = StateProvider<int>((ref) => 0);
