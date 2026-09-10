import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:zennyt/core/constants.dart';

class MediaGridTile extends StatelessWidget {
  final AssetEntity? asset;
  final bool isSelected;
  final bool isCamera;
  final VoidCallback onTap;

  const MediaGridTile({
    super.key,
    this.asset,
    required this.isSelected,
    required this.onTap,
    this.isCamera = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isCamera)
            ColoredBox(
              color: AppColors.chipUnselected,
              child: Icon(
                AppConstants.isCupertino
                    ? CupertinoIcons.camera
                    : Icons.photo_camera_outlined,
                color: AppColors.primaryGrey,
                size: 32,
              ),
            )
          else if (asset != null)
            _AssetThumbnail(asset: asset!)
          else
            const ColoredBox(color: AppColors.chipUnselected),

          if (!isCamera && asset?.type == AssetType.video)
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 36,
              ),
            ),

          if (isSelected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primaryBlue,
                  width: 3,
                ),
              ),
            ),

          if (!isCamera)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
        ],
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
      future: _buildThumbnail(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return snapshot.data!;
        }
        return const ColoredBox(color: AppColors.chipUnselected);
      },
    );
  }

  Future<Widget?> _buildThumbnail() async {
    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize.square(300),
    );
    if (data == null) return null;
    return Image.memory(data, fit: BoxFit.cover);
  }
}
