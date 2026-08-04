import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../domain/entities/fit_item.dart';
import '../bloc/fits_bloc.dart';
import '../widgets/fit_action_bar.dart';
import '../widgets/fit_card.dart';
import '../widgets/swipeable_fit_card.dart';

/// Écran "Fits" : deck de cartes à swiper (offres ou professionnels).
class FitsPage extends StatefulWidget {
  const FitsPage({super.key});
  @override
  State<FitsPage> createState() => _FitsPageState();
}

class _FitsPageState extends State<FitsPage> {
  final _cardKey = GlobalKey<SwipeableFitCardState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Fits',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: AppTheme.brandPink),
            tooltip: 'Matches',
            onPressed: () => context.push('/matches'),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.brandBlue),
            onPressed: () => context.push('/filter'),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: BlocBuilder<FitsBloc, FitsState>(
        builder: (context, state) {
          return Column(
            children: [
              _tabs(context, state.kind),
              Expanded(child: _deck(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _tabs(BuildContext context, FitKind kind) {
    Widget pill(String label, FitKind k) {
      final active = k == kind;
      return GestureDetector(
        onTap: () => context.read<FitsBloc>().add(FitsTabChanged(k)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.brandBlue : const Color(0xFFEDEEFB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppTheme.brandBlue)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        pill('Job Offers', FitKind.jobOffer),
        const SizedBox(width: 10),
        pill('Professionnels', FitKind.professional),
      ]),
    );
  }

  Widget _deck(BuildContext context, FitsState state) {
    if (state.status == FitsStatus.loading || state.status == FitsStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == FitsStatus.error) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(state.message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.read<FitsBloc>().add(const FitsStarted()),
            child: const Text('Réessayer'),
          ),
        ]),
      );
    }

    final item = state.current;
    if (item == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.done_all, size: 48, color: AppTheme.muted),
          const SizedBox(height: 8),
          const Text("Plus de profils pour l'instant."),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.read<FitsBloc>().add(const FitsStarted()),
            child: const Text('Recharger'),
          ),
        ]),
      );
    }

    final bloc = context.read<FitsBloc>();

    // État "match" : carte figée + bandeau + bouton Continue.
    if (state.matched) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(children: [
          Expanded(child: FitCard(item: item, matched: true)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => bloc.add(const MatchDismissed()),
              child: const Text('Continue'),
            ),
          ),
        ]),
      );
    }

    final next = (state.index + 1) < state.items.length
        ? state.items[state.index + 1]
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (next != null)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 0.94,
                      child: Opacity(opacity: 0.7, child: FitCard(item: next)),
                    ),
                  ),
                Positioned.fill(
                  child: SwipeableFitCard(
                    key: _cardKey,
                    item: item,
                    onLike: () => bloc.add(const FitSwiped(FitSwipe.like)),
                    onNope: () => bloc.add(const FitSwiped(FitSwipe.pass)),
                    onTap: item.kind == FitKind.jobOffer
                        ? () => context.push('/job-detail', extra: item)
                        : () => context.push('/candidate-profile'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FitActionBar(
            onUndo: () => bloc.add(const FitUndo()),
            onPass: () => _cardKey.currentState?.swipeLeft(),
            onLike: () => _cardKey.currentState?.swipeRight(),
            onSend: () => _cardKey.currentState?.swipeRight(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
