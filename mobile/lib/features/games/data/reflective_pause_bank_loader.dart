import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/entities/reflective_pause_bank.dart';

/// Charge la banque des 60 situations du « Temps Réflexif ».
///
/// Même politique que la banque du « Planning journalier » : l'asset fait
/// ~135 Ko et ne change pas en cours d'exécution, on le garde donc en cache.
class ReflectivePauseBankLoader {
  ReflectivePauseBankLoader._();

  static const String assetPath = 'assets/games/reflective_pause_bank.json';

  static ReflectivePauseBank? _cached;

  static ReflectivePauseBank? get cached => _cached;

  static Future<ReflectivePauseBank> load({AssetBundle? bundle}) async {
    final cached = _cached;
    if (cached != null) return cached;
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final bank = ReflectivePauseBank.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    return _cached = bank;
  }

  static void resetForTest() => _cached = null;
}
