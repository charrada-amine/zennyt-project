import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/router/app_router.dart';
import '../data/demo_games_repository.dart';
import '../data/games_mock_repository.dart';
import '../data/games_repository_impl.dart';
import '../domain/repositories/games_repository.dart';

/// Bascule mock / backend pour la feature games.
///
/// Par défaut la feature est **autonome** (mock) : jouable sans backend. Pour
/// brancher le vrai backend, deux voies équivalentes :
///
/// - `GAMES_MOCK=false` dans `mobile/.env` — un `flutter run` nu suffit alors,
///   c'est le chemin le plus court en développement local ;
/// - `flutter run --dart-define=GAMES_MOCK=false` — utile en CI ou pour un build
///   figé, et prioritaire sur rien : le `.env` gagne s'il définit la clé.
///
/// ⚠️ **« Je Décide » est la seule exception au mode autonome** : il exige le
/// backend. Sa banque de 120 items et sa clé de correction ne sont pas embarquées
/// dans l'application (voir l'exception de parité en tête de
/// `games_mock_repository.dart`). En mock, le jeu affiche « Journey unavailable »
/// au lieu de servir des scénarios inventés. Les autres jeux restent jouables
/// hors ligne, barème miroir compris.
bool get _useMock {
  // `dotenv.env` lève si `load` n'a pas encore tourné : c'est le cas dans les
  // tests widget, qui n'appellent pas `main`.
  if (dotenv.isInitialized) {
    final fromDotEnv = dotenv.env['GAMES_MOCK'];
    if (fromDotEnv != null && fromDotEnv.trim().isNotEmpty) {
      return fromDotEnv.trim().toLowerCase() != 'false';
    }
  }
  return const bool.fromEnvironment('GAMES_MOCK', defaultValue: true);
}

/// Source unique du repository games.
final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  // Build de démo « Lot 1 » : « Je décide » doit être jouable hors ligne comme
  // les quatre autres. [DemoGamesRepository] n'ajoute qu'une banque d'items
  // embarquée pour ce jeu — voir l'avertissement en tête de ce fichier : les
  // scores qu'elle produit n'ont AUCUNE valeur psychométrique.
  if (kLot1DemoBuild) return DemoGamesRepository();
  if (_useMock) return GamesMockRepository();
  return GamesRepositoryImpl(ref.watch(dioProvider));
});
