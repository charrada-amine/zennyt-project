import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';

/// Single source for the auth repository, backed by the configured Dio client
/// and secure token storage.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  ),
);
