part of 'feed_bloc.dart';

/// Événements entrants du BLoC fil d'actualité.
sealed class FeedEvent extends Equatable {
  const FeedEvent();
  @override
  List<Object?> get props => [];
}

/// Charger (ou recharger) le fil.
class FeedStarted extends FeedEvent {
  const FeedStarted();
}
