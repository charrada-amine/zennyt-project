import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/usecases/get_feed.dart';

part 'feed_event.dart';
part 'feed_state.dart';

/// BLoC du fil d'actualité. Reçoit ses dépendances par constructeur (GetIt) —
/// jamais de `GetIt.instance` au milieu du code, ce qui le garde testable.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final GetFeed getFeed;

  FeedBloc({required this.getFeed}) : super(const FeedInitial()) {
    on<FeedStarted>(_onStarted, transformer: restartable());
  }

  Future<void> _onStarted(FeedStarted event, Emitter<FeedState> emit) async {
    emit(const FeedLoading());
    final result = await getFeed(const NoParams());
    result.fold(
      (failure) => emit(FeedError(failure.message)),
      (posts) => emit(posts.isEmpty ? const FeedEmpty() : FeedReady(posts)),
    );
  }
}
