import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_bottom_nav.dart';
import '../bloc/feed_bloc.dart';
import '../widgets/feed_top_bar.dart';
import '../widgets/new_project_row.dart';
import '../widgets/post_card.dart';

/// Écran d'accueil (fil d'actualité). Le BLoC est fourni par le router via
/// GetIt — la page ne fait que réagir aux états.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F8),
      appBar: const FeedTopBar(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          return switch (state) {
            FeedInitial() || FeedLoading() =>
              const Center(child: CircularProgressIndicator()),
            FeedEmpty() => const Center(child: Text('Aucune publication.')),
            FeedError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<FeedBloc>().add(const FeedStarted()),
              ),
            FeedReady(:final posts) => RefreshIndicator(
                onRefresh: () async =>
                    context.read<FeedBloc>().add(const FeedStarted()),
                child: ListView.separated(
                  itemCount: posts.length + 1,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) return const NewProjectRow();
                    return PostCard(post: posts[index - 1]);
                  },
                ),
              ),
          };
        },
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
