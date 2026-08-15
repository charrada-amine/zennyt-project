import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:zennyt/core/constants.dart';

class AlbumPickerSheet {
  static Future<void> show(
    BuildContext context, {
    required List<AssetPathEntity> albums,
    required AssetPathEntity? selectedAlbum,
    required ValueChanged<AssetPathEntity> onAlbumSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.itemDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    final isSelected = album.id == selectedAlbum?.id;

                    return ListTile(
                      title: Text(
                        album.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.black,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primaryBlue,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        onAlbumSelected(album);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
