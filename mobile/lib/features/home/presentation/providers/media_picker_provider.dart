import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:file_picker/file_picker.dart';

class MediaPickerState {
  final List<AssetEntity> assets;
  final List<AssetPathEntity> albums;
  final AssetPathEntity? selectedAlbum;
  final Set<String> selectedIds;
  final bool isLoading;
  final bool hasPermission;

  const MediaPickerState({
    this.assets = const [],
    this.albums = const [],
    this.selectedAlbum,
    this.selectedIds = const {},
    this.isLoading = true,
    this.hasPermission = false,
  });

  int get selectedCount => selectedIds.length;

  MediaPickerState copyWith({
    List<AssetEntity>? assets,
    List<AssetPathEntity>? albums,
    AssetPathEntity? selectedAlbum,
    Set<String>? selectedIds,
    bool? isLoading,
    bool? hasPermission,
  }) {
    return MediaPickerState(
      assets: assets ?? this.assets,
      albums: albums ?? this.albums,
      selectedAlbum: selectedAlbum ?? this.selectedAlbum,
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class MediaPickerNotifier extends Notifier<MediaPickerState> {
  static const _pageSize = 120;

  @override
  MediaPickerState build() {
    Future.microtask(_initialize);
    return const MediaPickerState();
  }

  Future<void> _initialize() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      state = state.copyWith(isLoading: false, hasPermission: false);
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );

    if (albums.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        hasPermission: true,
        albums: [],
      );
      return;
    }

    final recents = albums.first;
    await _loadAlbum(recents, albums: albums);
  }

  Future<void> requestPermissionAndLoad() async {
    state = state.copyWith(isLoading: true);
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      await _initialize();
    } else {
      await PhotoManager.openSetting();
      final checkAgain = await PhotoManager.requestPermissionExtend();
      if (checkAgain.isAuth) {
        await _initialize();
      } else {
        state = state.copyWith(isLoading: false, hasPermission: false);
      }
    }
  }

  Future<void> selectAlbum(AssetPathEntity album) async {
    state = state.copyWith(isLoading: true, selectedAlbum: album);
    await _loadAlbum(album);
  }

  Future<void> _loadAlbum(
    AssetPathEntity album, {
    List<AssetPathEntity>? albums,
  }) async {
    final assets = await album.getAssetListPaged(page: 0, size: _pageSize);
    state = state.copyWith(
      assets: assets,
      albums: albums ?? state.albums,
      selectedAlbum: album,
      isLoading: false,
      hasPermission: true,
    );
  }

  void toggleSelection(String assetId) {
    final updated = Set<String>.from(state.selectedIds);
    if (updated.contains(assetId)) {
      updated.remove(assetId);
    } else {
      updated.add(assetId);
    }
    state = state.copyWith(selectedIds: updated);
  }

  List<AssetEntity> getSelectedAssets() {
    return state.assets
        .where((asset) => state.selectedIds.contains(asset.id))
        .toList();
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }
}

final mediaPickerProvider =
    NotifierProvider.autoDispose<MediaPickerNotifier, MediaPickerState>(
  MediaPickerNotifier.new,
);

final selectedPostMediaProvider =
    NotifierProvider<SelectedPostMediaNotifier, List<AssetEntity>>(
  SelectedPostMediaNotifier.new,
);

class SelectedPostMediaNotifier extends Notifier<List<AssetEntity>> {
  @override
  List<AssetEntity> build() => [];

  void setMedia(List<AssetEntity> assets) {
    state = List.from(assets);
  }

  void addMedia(List<AssetEntity> assets) {
    final existingIds = state.map((asset) => asset.id).toSet();
    final merged = [
      ...state,
      ...assets.where((asset) => !existingIds.contains(asset.id)),
    ];
    state = merged;
  }

  void removeMedia(String assetId) {
    state = state.where((asset) => asset.id != assetId).toList();
  }

  void clear() {
    state = [];
  }
}

final selectedPostDocumentsProvider =
    NotifierProvider<SelectedPostDocumentsNotifier, List<PlatformFile>>(
  SelectedPostDocumentsNotifier.new,
);

class SelectedPostDocumentsNotifier extends Notifier<List<PlatformFile>> {
  @override
  List<PlatformFile> build() => [];

  void setDocuments(List<PlatformFile> files) {
    state = List.from(files);
  }

  void addDocuments(List<PlatformFile> files) {
    final existingPaths = state.map((file) => file.path).toSet();
    final merged = [
      ...state,
      ...files.where(
        (file) => file.path != null && !existingPaths.contains(file.path),
      ),
    ];
    state = merged;
  }

  void removeDocument(String path) {
    state = state.where((file) => file.path != path).toList();
  }

  void clear() {
    state = [];
  }
}
