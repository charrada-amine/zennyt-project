import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../models/post_model.dart';

abstract class PostLocalDataSource {
  Future<void> cachePosts(List<PostModel> posts);
  Future<List<PostModel>> getCachedPosts();
  Future<void> clearCache();
}

class PostLocalDataSourceImpl implements PostLocalDataSource {
  final Box box;
  PostLocalDataSourceImpl(this.box);

  static const _postsKey = 'cached_posts';

  @override
  Future<void> cachePosts(List<PostModel> posts) async {
    final encoded = jsonEncode(posts.map((p) => p.toJson()).toList());
    await box.put(_postsKey, encoded);
  }

  @override
  Future<List<PostModel>> getCachedPosts() async {
    final raw = box.get(_postsKey) as String?;
    if (raw == null) throw CacheException('Aucune publication en cache');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    await box.delete(_postsKey);
  }
}
