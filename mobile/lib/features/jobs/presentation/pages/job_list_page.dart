import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/job_list_bloc.dart';
import '../widgets/job_card.dart';

/// Page liste d'offres. La construction du BLoC se fait via GetIt en amont
/// (BlocProvider dans le router) — la page ne fait que réagir aux états.
class JobListPage extends StatelessWidget {
  const JobListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offres d\'emploi')),
      body: BlocBuilder<JobListBloc, JobListState>(
        builder: (context, state) {
          return switch (state) {
            JobListInitial() || JobListLoading() =>
              const Center(child: CircularProgressIndicator()),
            JobListEmpty() =>
              const Center(child: Text('Aucune offre ne correspond.')),
            JobListError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<JobListBloc>().add(const JobsLoaded()),
              ),
            JobListLoaded(:final jobs, :final hasMore, :final isLoadingMore) =>
              _JobListView(jobs: jobs, hasMore: hasMore, isLoadingMore: isLoadingMore),
          };
        },
      ),
    );
  }
}

class _JobListView extends StatelessWidget {
  final List jobs;
  final bool hasMore;
  final bool isLoadingMore;
  const _JobListView({required this.jobs, required this.hasMore, required this.isLoadingMore});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200 && hasMore) {
          context.read<JobListBloc>().add(const NextPageRequested());
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async => context.read<JobListBloc>().add(const JobsLoaded()),
        child: ListView.builder(
          itemCount: jobs.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= jobs.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return JobCard(job: jobs[index]);
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
