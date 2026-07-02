import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/games_mock_repository.dart';
import '../data/games_repository_impl.dart';
import '../domain/repositories/games_repository.dart';

/// Bascule mock / backend pour la feature games.
///
/// Par défaut la feature est **autonome** (mock) : jouable sans backend. Pour
/// brancher le vrai backend, lancer avec `--dart-define=GAMES_MOCK=false` —
/// seule cette ligne décide, ni le contrôleur ni Flame ne changent.
const _useMock = bool.fromEnvironment('GAMES_MOCK', defaultValue: true);

/// Source unique du repository games.
final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  if (_useMock) return GamesMockRepository();
  return GamesRepositoryImpl(ref.watch(dioProvider));
});
