import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/profile_repository_impl.dart';
import '../domain/repositories/profile_repository.dart';

/// Repository for the candidate professional profile, wired to the shared Dio
/// client (auth interceptor applies automatically).
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(dioProvider)),
);
