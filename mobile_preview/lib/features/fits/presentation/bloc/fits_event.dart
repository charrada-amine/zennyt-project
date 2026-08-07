part of 'fits_bloc.dart';

enum FitSwipe { like, pass }

sealed class FitsEvent extends Equatable {
  const FitsEvent();
  @override
  List<Object?> get props => [];
}

class FitsStarted extends FitsEvent {
  const FitsStarted();
}

class FitsTabChanged extends FitsEvent {
  final FitKind kind;
  const FitsTabChanged(this.kind);
  @override
  List<Object?> get props => [kind];
}

class FitSwiped extends FitsEvent {
  final FitSwipe swipe;
  const FitSwiped(this.swipe);
  @override
  List<Object?> get props => [swipe];
}

class FitUndo extends FitsEvent {
  const FitUndo();
}

class MatchDismissed extends FitsEvent {
  const MatchDismissed();
}
