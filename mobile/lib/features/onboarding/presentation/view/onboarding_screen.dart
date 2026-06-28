import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/language_toggle.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/zennyt_logo.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/onboarding_page.dart';
import '../viewmodel/onboarding_viewmodel.dart';

/// Brand phrase rendered bold inside the welcome title; identical in every
/// language so the highlight logic stays language-agnostic.
const String _brandHighlight = 'Zennyt Careers';

String _onboardingBody(BuildContext context, OnboardingSlide slide) {
  switch (slide) {
    case OnboardingSlide.welcome:
      return context.l10n.onbWelcomeBody;
    case OnboardingSlide.games:
      return context.l10n.onbGamesBody;
    case OnboardingSlide.skills:
      return context.l10n.onbSkillsBody;
    case OnboardingSlide.opportunities:
      return context.l10n.onbOpportunitiesBody;
  }
}

String? _onboardingTitle(BuildContext context, OnboardingSlide slide) =>
    slide == OnboardingSlide.welcome ? context.l10n.onbWelcomeTitle : null;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingViewModelProvider.notifier).completeOnboarding();
    if (mounted) context.go(AppRoutes.login);
  }

  void _onNext(OnboardingState state) {
    if (state.isLastPage) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);
    final pages = state.pages;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-bleed swipeable photos.
          PageView.builder(
            controller: _pageController,
            onPageChanged: viewModel.onPageChanged,
            itemCount: pages.length,
            itemBuilder: (context, index) =>
                _OnboardingBackground(page: pages[index]),
          ),

          // White Zennyt Careers logo overlaid at the top, with the language
          // toggle pinned to the top-right over the photo.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ZennytLogo(
                      size: 40,
                      axis: Axis.horizontal,
                      showTagline: true,
                      wordmarkColor: Colors.white,
                    ),
                    Positioned(
                      right: AppSpacing.base,
                      top: 0,
                      bottom: 0,
                      child: const Center(child: LanguageToggle(light: true)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating bottom card with text + controls.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                child: CenteredConstrainedBox(
                  child: _OnboardingCard(
                    title: _onboardingTitle(
                      context,
                      pages[state.currentIndex].slide,
                    ),
                    body: _onboardingBody(
                      context,
                      pages[state.currentIndex].slide,
                    ),
                    isLastPage: state.isLastPage,
                    progress: (state.currentIndex + 1) / pages.length,
                    onNext: () => _onNext(state),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground({required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: page.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const ColoredBox(
            color: Colors.grey,
          ), // Using standard grey for placeholder
          errorWidget: (context, url, error) => const ColoredBox(
            color: Colors.grey,
            child: Icon(Icons.image_outlined, color: Colors.white, size: 48),
          ),
        ),
        // Subtle gradient so the white logo stays legible over bright photos.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x55102759), Color(0x00000000)],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.title,
    required this.body,
    required this.isLastPage,
    required this.progress,
    required this.onNext,
  });

  final String? title;
  final String body;
  final bool isLastPage;
  final double progress;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.cardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: context.colors.shadowColor != Colors.transparent
            ? AppShadows.lg
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            _Title(title: title!),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            body,
            style: AppTypography.bodyLarge.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          isLastPage
              ? Align(
                  alignment: Alignment.centerRight,
                  child: PrimaryButton(
                    label: context.l10n.getStarted,
                    expanded: false,
                    onPressed: onNext,
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 96, child: _ProgressBar(value: progress)),
                    const Spacer(),
                    GestureDetector(
                      onTap: onNext,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        context.l10n.next,
                        style: AppTypography.titleSmall.copyWith(
                          color: context
                              .colors
                              .actionCardFilled, // Accent equivalent
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.headlineMedium.copyWith(
      color: context.colors.textPrimary,
    );
    // Bold the brand phrase ("Zennyt Careers") within the title.
    final highlight = _brandHighlight;
    final index = title.indexOf(highlight);
    if (index < 0) {
      return Text(title, style: base);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: title.substring(0, index)),
          TextSpan(
            text: highlight,
            style: base.copyWith(fontWeight: AppTypography.bold),
          ),
          TextSpan(text: title.substring(index + highlight.length)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        builder: (context, animatedValue, _) => LinearProgressIndicator(
          value: animatedValue,
          minHeight: 6,
          backgroundColor: context.colors.divider,
          valueColor: AlwaysStoppedAnimation(context.colors.textPrimary),
        ),
      ),
    );
  }
}
