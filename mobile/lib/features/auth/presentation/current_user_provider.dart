import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/app_user.dart';
import 'auth_controller.dart';

/// Synchronous view of the signed-in user (null while loading / signed out).
///
/// Compatibility shim for the REC-04 screens, which read
/// `currentUserProvider` instead of unwrapping [authControllerProvider].
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).value;
});
