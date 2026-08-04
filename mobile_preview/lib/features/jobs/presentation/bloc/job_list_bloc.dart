import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/job.dart';
import '../../domain/entities/job_filter.dart';
import '../../domain/usecases/get_jobs.dart';

part 'job_list_event.dart';
part 'job_list_state.dart';

/// BLoC de la liste d'offres : pagination infinie + gestion d'erreur.
///
/// Reçoit ses dépendances par constructeur (injectées par GetIt) — jamais de
/// `GetIt.instance` au milieu du code, ce qui le garde testable.
class JobListBloc extends Bloc<JobListEvent, JobListState> {
  final GetJobs getJobs;
  static const _pageSize = 20;

  int _page = 0;
  JobFilter _filter = const JobFilter();

  JobListBloc({required this.getJobs}) : super(const JobListInitial()) {
    on<JobsLoaded>(_onLoaded, transformer: restartable());
    on<NextPageRequested>(_onNextPage, transformer: droppable());
  }

  Future<void> _onLoaded(JobsLoaded event, Emitter<JobListState> emit) async {
    _page = 0;
    _filter = event.filter;
    emit(const JobListLoading());

    final result = await getJobs(GetJobsParams(filter: _filter, page: _page, size: _pageSize));
    result.fold(
      (failure) => emit(JobListError(failure.message)),
      (jobs) => emit(jobs.isEmpty
          ? const JobListEmpty()
          : JobListLoaded(jobs: jobs, hasMore: jobs.length == _pageSize)),
    );
  }

  Future<void> _onNextPage(NextPageRequested event, Emitter<JobListState> emit) async {
    final current = state;
    if (current is! JobListLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    _page++;

    final result = await getJobs(GetJobsParams(filter: _filter, page: _page, size: _pageSize));
    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)), // garde la liste, stoppe le spinner
      (jobs) => emit(JobListLoaded(
        jobs: [...current.jobs, ...jobs],
        hasMore: jobs.length == _pageSize,
        isLoadingMore: false,
      )),
    );
  }
}
