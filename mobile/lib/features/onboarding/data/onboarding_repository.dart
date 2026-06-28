import '../../../core/constants/app_assets.dart';
import '../domain/entities/onboarding_page.dart';

/// Provides onboarding content. In the maquette this is static; later it can be
/// backed by a remote config / CMS without changing the presentation layer.
///
/// Only structural data (image + slide id) lives here — the copy is localized
/// in the view via the slide id.
class OnboardingRepository {
  const OnboardingRepository();

  List<OnboardingPage> getPages() => const [
    OnboardingPage(
      imageUrl: AppAssets.onboardingWelcome,
      slide: OnboardingSlide.welcome,
    ),
    OnboardingPage(
      imageUrl: AppAssets.onboardingGames,
      slide: OnboardingSlide.games,
    ),
    OnboardingPage(
      imageUrl: AppAssets.onboardingSkills,
      slide: OnboardingSlide.skills,
    ),
    OnboardingPage(
      imageUrl: AppAssets.onboardingOpportunities,
      slide: OnboardingSlide.opportunities,
    ),
  ];
}
