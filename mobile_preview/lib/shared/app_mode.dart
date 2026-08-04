import 'package:flutter/foundation.dart';

/// Mode courant (preview) : candidat (false) ou recruteur (true).
///
/// Le candidat et le recruteur partagent les mêmes écrans Home, Notifications,
/// Search, Fits — seul l'onglet central de la barre de navigation change
/// (Progress pour le candidat, Careers pour le recruteur). Ce drapeau global
/// permet à [AppBottomNav] d'afficher le bon onglet partout, sans dupliquer
/// les écrans. (Remplacera plus tard le rôle issu du JWT.)
final ValueNotifier<bool> appIsRecruiter = ValueNotifier<bool>(false);
