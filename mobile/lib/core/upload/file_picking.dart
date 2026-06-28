import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;

import 'picked_file.dart';

/// Thin, platform-safe wrappers around `image_picker` (photos) and the
/// first-party `file_selector` (documents). Returns a neutral [PickedFile] so
/// the rest of the app never depends on the plugin types directly.
class FilePickingService {
  FilePickingService([ImagePicker? imagePicker])
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// Pick a profile/logo image from the gallery or camera.
  Future<PickedFile?> pickImage({bool fromCamera = false}) async {
    final XFile? file = await _imagePicker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;
    // Always read bytes so the avatar preview renders on every platform
    // (no dart:io). Path is retained for a future real upload on mobile.
    return _toPickedFile(file);
  }

  /// Pick a PDF document (CV).
  Future<PickedFile?> pickPdf() async {
    const group = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
      uniformTypeIdentifiers: ['com.adobe.pdf'],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return null;
    return _toPickedFile(file);
  }

  /// Pick an image file via the document picker (e.g. company logo).
  Future<PickedFile?> pickImageDocument() async {
    const group = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
      mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
      uniformTypeIdentifiers: ['public.image'],
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return null;
    return _toPickedFile(file);
  }

  Future<PickedFile> _toPickedFile(XFile file) async {
    return PickedFile(
      name: file.name,
      path: kIsWeb ? null : file.path,
      bytes: await file.readAsBytes(),
    );
  }
}

final filePickingProvider = Provider<FilePickingService>(
  (ref) => FilePickingService(),
);
