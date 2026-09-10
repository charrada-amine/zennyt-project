import 'post_model.dart';

/// Résultat paginé retourné par le datasource.
class PaginatedPostsResult {
  final List<PostModel> posts;
  final int totalElements;
  final bool hasMore;

  const PaginatedPostsResult({
    required this.posts,
    required this.totalElements,
    required this.hasMore,
  });
}
