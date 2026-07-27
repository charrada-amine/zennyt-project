import 'package:hive/hive.dart';

import '../datasources/post_local_datasource.dart';
import '../models/post_model.dart';

class PostsCacheService {
  final PostLocalDataSource _localDataSource;
  final Box _syncBox;

  static const _lastSyncKey = 'last_sync';
  static const _lastPublicationDateKey = 'last_publication_date';

  static const int _cacheDays = 3;

  PostsCacheService({
    required PostLocalDataSource localDataSource,
    required Box syncBox,
  })  : _localDataSource = localDataSource,
        _syncBox = syncBox;

  Future<void> savePosts(List<PostModel> posts) async {
    if (posts.isEmpty) return;

    final pruned = _pruneOldPosts(posts);
    await _localDataSource.cachePosts(pruned);

    final latestDate = _findLatestCreatedAt(pruned);
    if (latestDate != null) {
      await _saveLastPublicationDate(latestDate);
    }
  }

  Future<List<PostModel>> loadPosts() async {
    try {
      return await _localDataSource.getCachedPosts();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearOldPosts(List<PostModel> posts) async {
    final pruned = _pruneOldPosts(posts);
    await _localDataSource.cachePosts(pruned);
  }

  DateTime? lastPublicationDate() {
    final raw = _syncBox.get(_lastPublicationDateKey) as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveLastSync(DateTime dateTime) async {
    await _syncBox.put(_lastSyncKey, dateTime.toIso8601String());
  }

  DateTime? loadLastSync() {
    final raw = _syncBox.get(_lastSyncKey) as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clearCache() async {
    await _localDataSource.clearCache();
    await _syncBox.delete(_lastSyncKey);
    await _syncBox.delete(_lastPublicationDateKey);
  }

  List<PostModel> _pruneOldPosts(List<PostModel> posts) {
    final latestDate = _findLatestCreatedAt(posts);
    if (latestDate == null) return posts;

    final cutoffDate = DateTime(
      latestDate.year,
      latestDate.month,
      latestDate.day,
    ).subtract(Duration(days: _cacheDays - 1));

    return posts.where((post) {
      if (post.createdAt == null) return true;
      final postDate = DateTime(
        post.createdAt!.year,
        post.createdAt!.month,
        post.createdAt!.day,
      );
      return !postDate.isBefore(cutoffDate);
    }).toList();
  }

  DateTime? _findLatestCreatedAt(List<PostModel> posts) {
    DateTime? latest;
    for (final post in posts) {
      if (post.createdAt != null) {
        if (latest == null || post.createdAt!.isAfter(latest)) {
          latest = post.createdAt;
        }
      }
    }
    return latest;
  }

  Future<void> _saveLastPublicationDate(DateTime date) async {
    await _syncBox.put(_lastPublicationDateKey, date.toIso8601String());
  }
}
