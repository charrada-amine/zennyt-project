import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../data/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../presentation/auth_controller.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final webSocketConnectionProvider = Provider<void>((ref) {
  final authState = ref.watch(authControllerProvider);
  final ws = ref.read(webSocketServiceProvider);
  final tokenStorage = ref.read(tokenStorageProvider);

  authState.when(
    data: (user) async {
      if (user != null) {
        final token = await tokenStorage.readAccessToken();
        const testUuidMap = {
          '2': '05e4fcc0-e555-4016-bc2d-9af4ee1cf38f',
          '4': '1b9a9ff0-13d6-40dc-bf04-222e93708c3e',
        };
        final testUuid = testUuidMap[user.id] ?? user.id;
        ws.connect(userId: testUuid, authToken: token);
      } else {
        ws.disconnect();
      }
    },
    loading: () {},
    error: (_, __) => ws.disconnect(),
  );
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});
