import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/entities/strategic_choices_bank.dart';

/// Charge la banque des 60 situations « Choix Stratégiques ».
///
/// Même politique que les autres banques : l'asset fait ~119 Ko et ne change
/// pas en cours d'exécution, on le garde donc en cache.
class StrategicChoicesBankLoader {
  StrategicChoicesBankLoader._();

  static const String assetPath = 'assets/games/strategic_choices_bank.json';

  static StrategicChoicesBank? _cached;

  static StrategicChoicesBank? get cached => _cached;

  static Future<StrategicChoicesBank> load({AssetBundle? bundle}) async {
    final cached = _cached;
    if (cached != null) return cached;
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final bank = StrategicChoicesBank.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    return _cached = bank;
  }

  static void resetForTest() => _cached = null;
}
