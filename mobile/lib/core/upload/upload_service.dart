import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'picked_file.dart';

/// What a picked file represents, so a real upload backend can route it.
enum UploadKind { avatar, cv, companyLogo }

/// Turns a locally [PickedFile] into a hosted URL the backend can store.
///
/// The identity backend currently exposes no file-upload endpoint, so the
/// default [NoopUploadService] returns `null` (no URL). Swap the provider for a
/// real implementation (e.g. `POST /media`) once that endpoint exists — no UI
/// changes required.
abstract class UploadService {
  Future<String?> upload(PickedFile file, {required UploadKind kind});
}

class NoopUploadService implements UploadService {
  const NoopUploadService();

  @override
  Future<String?> upload(PickedFile file, {required UploadKind kind}) async =>
      null;
}

final uploadServiceProvider = Provider<UploadService>(
  (ref) => const NoopUploadService(),
);
