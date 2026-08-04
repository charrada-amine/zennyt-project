import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../domain/entities/suggestion.dart';
import '../bloc/search_bloc.dart';
import '../widgets/suggestion_card.dart';

/// Écran de recherche (offres / professionnels) avec grille de suggestions.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

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
        title: const Text('Search',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: const _SearchBody(),
    );
  }
}

class _SearchBody extends StatefulWidget {
  const _SearchBody();
  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (v) =>
                          context.read<SearchBloc>().add(SearchQueryChanged(v)),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF4F5F8),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.brandBlue),
                    ),
                    child: const Icon(Icons.tune, color: AppTheme.brandBlue),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _pill(context, 'Job Offers', SuggestionKind.jobOffer, state.kind),
                  const SizedBox(width: 10),
                  _pill(context, 'Professionnels', SuggestionKind.professional,
                      state.kind),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Suggestions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _grid(context, state)),
          ],
        );
      },
    );
  }

  Widget _pill(BuildContext context, String label, SuggestionKind kind,
      SuggestionKind selected) {
    final active = kind == selected;
    return GestureDetector(
      onTap: () => context.read<SearchBloc>().add(SearchTabChanged(kind)),
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

  Widget _grid(BuildContext context, SearchState state) {
    if (state.status == SearchStatus.loading ||
        state.status == SearchStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == SearchStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.read<SearchBloc>().add(const SearchStarted()),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (state.suggestions.isEmpty) {
      return const Center(child: Text('Aucun résultat.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemCount: state.suggestions.length,
      itemBuilder: (context, i) => SuggestionCard(s: state.suggestions[i]),
    );
  }
}
