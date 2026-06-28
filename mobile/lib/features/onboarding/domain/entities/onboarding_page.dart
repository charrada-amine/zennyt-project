import 'package:flutter/foundation.dart';

/// Identifies an onboarding slide so its (localized) title/body can be resolved
/// in the presentation layer rather than baked in as literal text.
enum OnboardingSlide { welcome, games, skills, opportunities }

/// A single onboarding slide: its background image and which slide it is.
/// The user-facing copy is resolved from localizations in the view.
@immutable
class OnboardingPage {
  const OnboardingPage({required this.imageUrl, required this.slide});

  final String imageUrl;
  final OnboardingSlide slide;

  /// Only the first slide carries a bold heading in the design.
  bool get hasTitle => slide == OnboardingSlide.welcome;
}
