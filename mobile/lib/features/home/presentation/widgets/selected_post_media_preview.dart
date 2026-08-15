import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:zennyt/core/constants.dart';

class SelectedPostMediaPreview extends StatelessWidget {
  final List<AssetEntity> media;
  final ValueChanged<String> onRemove;

  const SelectedPostMediaPreview({
    super.key,
    required this.media,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: media
            .map(
              (asset) => _MediaPreviewTile(
                asset: asset,
                onRemove: () => onRemove(asset.id),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MediaPreviewTile extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onRemove;

  const _MediaPreviewTile({
    required this.asset,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _AssetThumbnail(asset: asset),
            if (asset.type == AssetType.video)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppConstants.isCupertino
                        ? CupertinoIcons.xmark
                        : Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;

  const _AssetThumbnail({required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget?>(
      future: _loadThumbnail(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return snapshot.data!;
        }
        return const ColoredBox(color: AppColors.chipUnselected);
      },
    );
  }

  Future<Widget?> _loadThumbnail() async {
    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize.square(200),
    );
    if (data == null) return null;
    return Image.memory(data, fit: BoxFit.cover);
  }
}
