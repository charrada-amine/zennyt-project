import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configuration appliquée à TOUS les tests widget du projet.
///
/// Sans elle, les tests dessinent le texte et les icônes avec la police de
/// remplacement de `flutter_test` : des rectangles pleins. C'est sans effet sur
/// les assertions (`find.text` lit l'arbre, pas les pixels), mais les captures
/// de `matchesGoldenFile` en deviennent illisibles — donc inutiles pour une
/// revue visuelle. On charge ici les vraies polices : l'Inter de l'app et le
/// MaterialIcons du SDK.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  await _loadFont('Inter', ['assets/fonts/Inter-VariableFont.ttf']);

  // MaterialIcons vit dans le cache d'artefacts du SDK, pas dans le paquet.
  // Sa profondeur dépend de la plateforme (l'exécutable est `flutter_tester`,
  // enfoui sous `artifacts/engine/<plateforme>/`) : on remonte donc les parents
  // jusqu'à trouver `material_fonts`, plutôt que de coder un nombre de niveaux.
  final materialFonts = _findMaterialFontsDir();
  if (materialFonts != null) {
    await _loadFont('MaterialIcons', [
      '${materialFonts.path}/MaterialIcons-Regular.otf',
    ]);
    // Roboto est la police de repli déclarée par l'app
    // ([AppTypography.fontFamilyFallback]) et la valeur par défaut de tout
    // `TextStyle` sans `fontFamily`. Sans elle, ces textes-là — les libellés de
    // cartes de « J'investigue », par exemple — se dessinent en rectangles.
    await _loadFont('Roboto', [
      '${materialFonts.path}/Roboto-Regular.ttf',
      '${materialFonts.path}/Roboto-Bold.ttf',
    ]);
  }

  await testMain();
}

/// Remonte les parents de l'exécutable de test jusqu'au dossier
/// `material_fonts` du cache du SDK : sa profondeur dépend de la plateforme
/// (l'exécutable est `flutter_tester`, enfoui sous `artifacts/engine/<os>/`),
/// donc on cherche au lieu de coder un nombre de niveaux.
Directory? _findMaterialFontsDir() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final candidate = Directory('${dir.path}/material_fonts');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break; // racine atteinte
    dir = parent;
  }
  return null;
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  var found = false;
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    found = true;
    loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
  }
  if (!found) return; // police absente : on garde le rendu par défaut
  await loader.load();
}
