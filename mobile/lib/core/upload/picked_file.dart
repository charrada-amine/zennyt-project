import 'package:flutter/foundation.dart';

/// A file the user picked locally (image or document), before any upload.
@immutable
class PickedFile {
  const PickedFile({required this.name, this.path, this.bytes});

  /// Display name, e.g. `millie-cv.pdf`.
  final String name;

  /// Filesystem path (null on web).
  final String? path;

  /// In-memory bytes (used on web, or when read eagerly).
  final Uint8List? bytes;

  bool get isImage {
    final lower = name.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }
}
