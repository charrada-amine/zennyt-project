import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Decouples the network layer from the auth session.
///
/// The [AuthInterceptor] emits a session-expired event when a token refresh
/// ultimately fails; the auth session controller listens and tears down the
/// session (which in turn triggers the router redirect to login).
class AuthEventBus {
  final StreamController<void> _sessionExpired =
      StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _sessionExpired.stream;

  void notifySessionExpired() {
    if (!_sessionExpired.isClosed) _sessionExpired.add(null);
  }

  void dispose() => _sessionExpired.close();
}

final authEventBusProvider = Provider<AuthEventBus>((ref) {
  final bus = AuthEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});
