/// Items of a list response, whether the backend sends a bare JSON array or a
/// page (`{"content": [...], "page": {...}}`, `PageResponse` côté serveur).
///
/// Plusieurs routes (offres du recruteur, matchs) sont passées en pagination
/// côté serveur alors que l'app lisait encore une liste nue : le cast échouait
/// et l'écran affichait « Failed to load ». Lire via ce helper évite que le
/// prochain changement de forme casse à nouveau silencieusement.
List<Map<String, dynamic>> pageItems(Object? data) {
  final raw = switch (data) {
    final List<dynamic> list => list,
    final Map<String, dynamic> page when page['content'] is List => page['content'] as List,
    _ => const <dynamic>[],
  };
  return raw.whereType<Map<String, dynamic>>().toList(growable: false);
}
