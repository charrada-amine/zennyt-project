import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';

import '../providers/media_picker_provider.dart';
import '../widgets/album_picker_sheet.dart';
import '../widgets/media_grid_tile.dart';
import '../widgets/media_picker_header.dart';

class MediaPickerPage extends ConsumerWidget {
  const MediaPickerPage({super.key});

  Future<void> _openCamera(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null || !context.mounted) return;

    final bytes = await photo.readAsBytes();
    final entity = await PhotoManager.editor.saveImage(
      bytes,
      filename: photo.name,
    );
    if (!context.mounted) return;

    ref.read(selectedPostMediaProvider.notifier).addMedia([entity]);
    ref.read(mediaPickerProvider.notifier).clearSelection();
    context.pop();
  }

  void _confirmSelection(BuildContext context, WidgetRef ref) {
    final selected = ref.read(mediaPickerProvider.notifier).getSelectedAssets();
    ref.read(selectedPostMediaProvider.notifier).addMedia(selected);
    ref.read(mediaPickerProvider.notifier).clearSelection();
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(mediaPickerProvider);
    final notifier = ref.read(mediaPickerProvider.notifier);

    final albumName = state.selectedAlbum?.name ?? l10n.mediaRecents;

    return Scaffold(
      backgroundColor: AppColors.chipUnselected,
      body: SafeArea(
        child: Column(
          children: [
            MediaPickerHeader(
              albumName: albumName,
              selectedCount: state.selectedCount,
              onAlbumTap: state.albums.isEmpty
                  ? () {}
                  : () => AlbumPickerSheet.show(
                        context,
                        albums: state.albums,
                        selectedAlbum: state.selectedAlbum,
                        onAlbumSelected: notifier.selectAlbum,
                      ),
              onAddTap: () => _confirmSelection(context, ref),
            ),
            Expanded(
              child: _buildBody(context, ref, state, notifier, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    MediaPickerState state,
    MediaPickerNotifier notifier,
    AppLocalizations l10n,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasPermission) {
      final colors = context.colors;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: colors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.mediaPermissionDenied,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  notifier.requestPermissionAndLoad();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.settings, size: 20),
                label: const Text(
                  'Allow Access / Open Settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final itemCount = state.assets.length + 1;

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return MediaGridTile(
            isCamera: true,
            isSelected: false,
            onTap: () => _openCamera(context, ref),
          );
        }

        final asset = state.assets[index - 1];
        final isSelected = state.selectedIds.contains(asset.id);

        return MediaGridTile(
          asset: asset,
          isSelected: isSelected,
          onTap: () => notifier.toggleSelection(asset.id),
        );
      },
    );
  }
}
