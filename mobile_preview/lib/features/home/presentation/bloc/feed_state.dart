part of 'feed_bloc.dart';

/// États sortants du BLoC fil d'actualité.
sealed class FeedState extends Equatable {
  const FeedState();
  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedReady extends FeedState {
  final List<FeedPost> posts;
  const FeedReady(this.posts);
  @override
  List<Object?> get props => [posts];
}

class FeedEmpty extends FeedState {
  const FeedEmpty();
}

class FeedError extends FeedState {
  final String message;
  const FeedError(this.message);
  @override
  List<Object?> get props => [message];
}
