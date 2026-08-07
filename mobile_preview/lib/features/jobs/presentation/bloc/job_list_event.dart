part of 'job_list_bloc.dart';

/// Événements entrants du BLoC liste d'offres.
sealed class JobListEvent extends Equatable {
  const JobListEvent();
  @override
  List<Object?> get props => [];
}

/// Charger la première page (ou recharger avec un nouveau filtre).
class JobsLoaded extends JobListEvent {
  final JobFilter filter;
  const JobsLoaded({this.filter = const JobFilter()});
  @override
  List<Object?> get props => [filter];
}

/// Charger la page suivante (pagination infinie).
class NextPageRequested extends JobListEvent {
  const NextPageRequested();
}
