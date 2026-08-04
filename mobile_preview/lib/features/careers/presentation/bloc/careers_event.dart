part of 'careers_bloc.dart';

sealed class CareersEvent extends Equatable {
  const CareersEvent();
  @override
  List<Object?> get props => [];
}

class CareersStarted extends CareersEvent {
  const CareersStarted();
}
