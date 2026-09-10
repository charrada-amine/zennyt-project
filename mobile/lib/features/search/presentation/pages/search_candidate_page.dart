import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/zennyt_loader.dart';
import '../../../fits/presentation/widgets/fit_scores_grid.dart';
import '../providers/search_provider.dart';

class SearchCandidatePage extends ConsumerStatefulWidget {
  const SearchCandidatePage({super.key});
  @override
  ConsumerState<SearchCandidatePage> createState() =>
      _SearchCandidatePageState();
}

class _SearchCandidatePageState extends ConsumerState<SearchCandidatePage> {
  late final _searchController = TextEditingController(
    text: ref.read(searchQueryProvider),
  );
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final filters = ref.watch(searchFiltersProvider);
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: const CustomAppBar(title: 'Search'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    hint: 'Role, company or location',
                    controller: _searchController,
                    prefixIcon: Icons.search_rounded,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).update(value),
                  ),
                ),
                const SizedBox(width: 12),
                Badge(
                  isLabelVisible: filters.isActive,
                  child: IconButton.filledTonal(
                    tooltip: 'Filters',
                    onPressed: () => context.pushNamed(AppRoutes.nSearchFilter),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 54),
                    ),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
            if (filters.isActive)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      ref.read(searchFiltersProvider.notifier).clear(),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear filters'),
                ),
              ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'Explore possibilities'
                        : 'Search results',
                    style: AppTypography.headlineLarge.copyWith(
                      color: colors.textDarkBlue,
                      letterSpacing: -.7,
                    ),
                  ),
                ),
                if (results.hasValue)
                  Text(
                    '${results.value!.length}',
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (results.isLoading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: ZennytLoader()),
              )
            else if (results.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Could not load results. Check your connection and try again.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              )
            else if (results.value?.isEmpty ?? true)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Icon(Icons.search_rounded, size: 38, color: colors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'No results yet',
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.textDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search or adjust your filters.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              FitScoresGrid(items: results.value!),
          ],
        ),
      ),
    );
  }
}
