import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/onboarding_local_data_source.dart';
import '../../data/onboarding_repository.dart';
import '../../domain/entities/onboarding_page.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => const OnboardingRepository(),
);

/// Immutable UI state for the onboarding flow.
class OnboardingState {
  const OnboardingState({required this.pages, this.currentIndex = 0});

  final List<OnboardingPage> pages;
  final int currentIndex;

  bool get isLastPage => currentIndex == pages.length - 1;

  OnboardingState copyWith({int? currentIndex}) => OnboardingState(
    pages: pages,
    currentIndex: currentIndex ?? this.currentIndex,
  );
}

/// ViewModel for the onboarding screen. Holds the page list and the currently
/// visible page index.
class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final pages = ref.read(onboardingRepositoryProvider).getPages();
    return OnboardingState(pages: pages);
  }

  void onPageChanged(int index) {
    state = state.copyWith(currentIndex: index);
  }

  /// Marks onboarding as seen so it never shows again on subsequent launches.
  Future<void> completeOnboarding() {
    return ref.read(onboardingLocalDataSourceProvider).setCompleted();
  }
}

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );
