import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/entities/day_stack_bank.dart';

/// Charge la banque de tâches du « Planning journalier » depuis les assets.
///
/// Le chargement est mis en cache : l'asset fait ~54 Ko et la banque ne change
/// pas en cours d'exécution. Une partie qui recommence ne le relit donc pas.
class DayStackBankLoader {
  DayStackBankLoader._();

  static const String assetPath = 'assets/games/day_stack_bank.json';

  static DayStackBank? _cached;

  /// Banque déjà chargée, ou `null`. Permet un accès synchrone aux écrans qui
  /// l'ont déjà demandée une fois.
  static DayStackBank? get cached => _cached;

  static Future<DayStackBank> load({AssetBundle? bundle}) async {
    final cached = _cached;
    if (cached != null) return cached;
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final bank = DayStackBank.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    return _cached = bank;
  }

  /// Vide le cache — un test qui charge depuis un bundle truqué ne doit pas
  /// hériter de ce qu'un test précédent a lu.
  static void resetForTest() => _cached = null;
}
