part of 'job_list_bloc.dart';

/// États sortants du BLoC liste d'offres.
sealed class JobListState extends Equatable {
  const JobListState();
  @override
  List<Object?> get props => [];
}

class JobListInitial extends JobListState {
  const JobListInitial();
}

class JobListLoading extends JobListState {
  const JobListLoading();
}

class JobListLoaded extends JobListState {
  final List<Job> jobs;
  final bool hasMore;
  final bool isLoadingMore;
  const JobListLoaded({required this.jobs, this.hasMore = true, this.isLoadingMore = false});

  JobListLoaded copyWith({List<Job>? jobs, bool? hasMore, bool? isLoadingMore}) => JobListLoaded(
        jobs: jobs ?? this.jobs,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [jobs, hasMore, isLoadingMore];
}

class JobListEmpty extends JobListState {
  const JobListEmpty();
}

class JobListError extends JobListState {
  final String message;
  const JobListError(this.message);
  @override
  List<Object?> get props => [message];
}
