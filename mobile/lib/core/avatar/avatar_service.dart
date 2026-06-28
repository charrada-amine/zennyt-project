import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds deterministic avatar image URLs via DiceBear (free, no API key).
///
/// A generated avatar is a real, hosted URL, so it persists end-to-end today
/// (stored in `profileImageUrl`) even though there is no file-upload endpoint
/// for personal photos yet.
class AvatarService {
  const AvatarService();

  static const _base = 'https://api.dicebear.com/9.x';

  /// Illustrated human-style avatars (matches the app's look).
  static const _style = 'avataaars';

  /// A stable avatar for a given seed (e.g. the user's email).
  String defaultFor(String seed) {
    final s = seed.trim().isEmpty ? 'zennyt' : seed.trim();
    return '$_base/$_style/png?seed=${Uri.encodeComponent(s)}';
  }

  /// A fresh random avatar (used by the "shuffle" action).
  String random() =>
      defaultFor('zennyt-${DateTime.now().microsecondsSinceEpoch}');
}

final avatarServiceProvider = Provider<AvatarService>(
  (ref) => const AvatarService(),
);
