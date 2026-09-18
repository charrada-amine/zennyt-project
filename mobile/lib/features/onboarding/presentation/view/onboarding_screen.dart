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
import '../../../../core/audio/sound_service.dart';
import '../../domain/entities/onboarding_page.dart';
import '../viewmodel/onboarding_viewmodel.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

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

String _onboardingTitle(BuildContext context, OnboardingSlide slide) =>
    switch (slide) {
      OnboardingSlide.welcome => context.l10n.onbWelcomeTitle,
      OnboardingSlide.games => context.l10n.onbGamesTitle,
      OnboardingSlide.skills => context.l10n.onbSkillsTitle,
      OnboardingSlide.opportunities => context.l10n.onbOpportunitiesTitle,
    };

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
        duration: AppMotion.duration(context, AppMotion.navigation),
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
      backgroundColor: AppColors.primaryDarkest,
      body: Stack(
        children: [
          // Full-bleed swipeable photos.
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              SoundService.instance.vibrateSelection();
              viewModel.onPageChanged(index);
            },
            itemCount: pages.length,
            itemBuilder: (context, index) => AnimatedBuilder(
              animation: _pageController,
              child: _OnboardingBackground(page: pages[index]),
              builder: (context, child) {
                final position =
                    _pageController.hasClients &&
                        _pageController.position.hasContentDimensions
                    ? _pageController.page ?? 0
                    : 0.0;
                final distance = (position - index).abs().clamp(0.0, 1.0);
                return Transform.scale(
                  scale: AppMotion.reduced(context) ? 1 : 1 + distance * .06,
                  child: child,
                );
              },
            ),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ZennytLogo(
                            size: 42,
                            axis: Axis.horizontal,
                            showTagline: true,
                            wordmarkColor: Colors.white,
                          ),
                        ),
                      ),
                      const LanguageToggle(light: true),
                    ],
                  ),
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .65,
                    ),
                    child: SingleChildScrollView(
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
            color: AppColors.primaryDeep,
          ), // Using standard grey for placeholder
          errorWidget: (context, url, error) => const ColoredBox(
            color: AppColors.primaryDeep,
            child: AppIcon(HugeIcons.strokeRoundedImage01, color: Colors.white, size: 48),
          ),
        ),
        // Subtle gradient so the white logo stays legible over bright photos.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xAA102759), Color(0x00102759), Color(0xCC102759)],
              stops: [0, .45, 1],
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.colors.cardSurface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: context.colors.shadowColor != Colors.transparent
            ? AppShadows.lg
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _ProgressBar(value: progress)),
              const SizedBox(width: 20),
              Text(
                '${(progress * 4).round().toString().padLeft(2, '0')} / 04',
                style: AppTypography.overline.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
          PrimaryButton(
            label: isLastPage ? context.l10n.getStarted : context.l10n.next,
            icon: HugeIcons.strokeRoundedArrowRight02,
            backgroundColor: context.colors.accent,
            onPressed: onNext,
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
    final base = AppTypography.displaySmall.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -.8,
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
        duration: AppMotion.duration(context, AppMotion.navigation),
        curve: Curves.easeOut,
        builder: (context, animatedValue, _) => LinearProgressIndicator(
          value: animatedValue,
          minHeight: 6,
          backgroundColor: context.colors.divider,
          valueColor: AlwaysStoppedAnimation(context.colors.accent),
        ),
      ),
    );
  }
}
