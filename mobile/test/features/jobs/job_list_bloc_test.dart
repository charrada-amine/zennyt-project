import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:progress_careers/core/error/failures.dart';
import 'package:progress_careers/features/jobs/domain/entities/job.dart';
import 'package:progress_careers/features/jobs/domain/entities/job_filter.dart';
import 'package:progress_careers/features/jobs/domain/usecases/get_jobs.dart';
import 'package:progress_careers/features/jobs/presentation/bloc/job_list_bloc.dart';

class MockGetJobs extends Mock implements GetJobs {}

void main() {
  late MockGetJobs getJobs;

  setUpAll(() => registerFallbackValue(
      const GetJobsParams(filter: JobFilter())));

  setUp(() => getJobs = MockGetJobs());

  const job = Job(
    id: '1', title: 'Dev Backend', companyName: 'Acme',
    location: 'Tunis', remoteAllowed: true,
    contractType: 'FULL_TIME', experienceLevel: 'MID',
  );

  blocTest<JobListBloc, JobListState>(
    'émet [Loading, Loaded] quand le chargement réussit',
    build: () {
      when(() => getJobs(any())).thenAnswer((_) async => const Right([job]));
      return JobListBloc(getJobs: getJobs);
    },
    act: (bloc) => bloc.add(const JobsLoaded()),
    expect: () => [
      const JobListLoading(),
      const JobListLoaded(jobs: [job], hasMore: false),
    ],
  );

  blocTest<JobListBloc, JobListState>(
    'émet [Loading, Error] quand le use case échoue',
    build: () {
      when(() => getJobs(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      return JobListBloc(getJobs: getJobs);
    },
    act: (bloc) => bloc.add(const JobsLoaded()),
    expect: () => [
      const JobListLoading(),
      isA<JobListError>(),
    ],
  );

  blocTest<JobListBloc, JobListState>(
    'émet [Loading, Empty] quand aucune offre',
    build: () {
      when(() => getJobs(any())).thenAnswer((_) async => const Right([]));
      return JobListBloc(getJobs: getJobs);
    },
    act: (bloc) => bloc.add(const JobsLoaded()),
    expect: () => [const JobListLoading(), const JobListEmpty()],
  );
}
