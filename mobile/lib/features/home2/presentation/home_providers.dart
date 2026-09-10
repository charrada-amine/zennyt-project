import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_repository.dart';

/// Provides the static [HomeRepository] backing the Home feed.
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => const HomeRepository(),
);
