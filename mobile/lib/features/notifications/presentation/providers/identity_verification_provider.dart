import 'package:flutter_riverpod/flutter_riverpod.dart';

class IdentityVerificationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markVerified() => state = true;
}

final identityVerificationProvider =
    NotifierProvider<IdentityVerificationNotifier, bool>(
  IdentityVerificationNotifier.new,
);
