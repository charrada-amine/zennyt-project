import 'dart:async';

import '../../domain/repositories/post_repository.dart';

class PostsSyncService {
  final PostRepository _repository;
  Timer? _timer;

  static const _syncInterval = Duration(minutes: 10);

  PostsSyncService({required PostRepository repository})
      : _repository = repository;

  void startPeriodicSync() {
    _timer?.cancel();
    _timer = Timer.periodic(_syncInterval, (_) => syncPosts());
  }

  void stopPeriodicSync() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> syncPosts() async {
    await _repository.getPosts(page: 0, size: 100);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
