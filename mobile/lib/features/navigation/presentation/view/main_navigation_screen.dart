import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../../../fits/presentation/view/fits_screen.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../progress/presentation/view/progress_screen.dart';
import '../../../search/presentation/view/search_screen.dart';
import '../viewmodel/nav_tab_provider.dart';
import 'package:zennyt/shared/icons/app_icons.dart';

/// Hauteur de la barre d'onglets native iOS 26 (Liquid Glass), qui flotte
/// au-dessus du contenu au lieu de le repousser.
const double _kNativeTabBarHeight = 50;

/// The main app navigation shown after authentication. Hosts the five
/// destinations in an [IndexedStack] (state is preserved across tab switches)
/// under a platform-native tab bar: Liquid Glass `UITabBar` on iOS 26+,
/// `CupertinoTabBar` on older iOS, Material 3 `NavigationBar` on Android.
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key, this.initialTab});

  final int? initialTab;

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int? _localTab;

  @override
  void initState() {
    super.initState();
    _localTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final initialTab = widget.initialTab;
    if (initialTab != null && initialTab != oldWidget.initialTab) {
      _localTab = initialTab;
    }
  }

  void _select(int index, int current) {
    // Build de démo « Lot 1 » : seul l'onglet qui porte les jeux répond ; les
    // autres restent visibles mais inertes (cf. kLot1DemoBuild).
    if (kLot1DemoBuild && index != kLot1DemoTabIndex) return;
    if (index == current) return;
    SoundService.instance.vibrateSelection();
    setState(() => _localTab = null);
    ref.read(navTabProvider.notifier).select(index);
  }

  @override
  Widget build(BuildContext context) {
    final int tab = _localTab ?? ref.watch(navTabProvider);
    final colors = context.colors;
    final isRecruiter =
        ref.watch(currentUserProvider)?.role == UserRole.recruiter;
    final nativeGlass = PlatformInfo.isIOS26OrHigher();

    AdaptiveNavigationDestination destination(
      String label,
      String sfSymbol,
      AppIconData icon, {
      String? selectedSfSymbol,
    }) {
      return AdaptiveNavigationDestination(
        label: label,
        // La barre native iOS 26 n'accepte que des SF Symbols ; ailleurs on
        // garde les icônes de la marque.
        icon: nativeGlass ? sfSymbol : AppIcon(icon),
        selectedIcon: nativeGlass ? selectedSfSymbol : null,
      );
    }

    Widget body = IndexedStack(
      index: tab,
      children: const [
        HomePage(),
        FitsScreen(),
        ProgressScreen(),
        SearchScreen(),
        NotificationsPage(),
      ],
    );
    if (nativeGlass) {
      // La barre Liquid Glass flotte au-dessus des onglets : on réserve sa
      // hauteur dans les insets pour que SafeArea / Scaffold des pages gardent
      // leur dernier élément visible, tout en laissant défiler dessous.
      final mq = MediaQuery.of(context);
      body = MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(
            bottom: mq.padding.bottom + _kNativeTabBarHeight,
          ),
        ),
        child: body,
      );
    }

    return AdaptiveScaffold(
      body: ColoredBox(color: colors.scaffoldBg, child: body),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: tab,
        onTap: (index) => _select(index, tab),
        // Sur Android le package en fait la couleur de l'indicateur M3 : on
        // laisse le NavigationBarTheme de l'app décider.
        selectedItemColor: PlatformInfo.isIOS
            ? Theme.of(context).colorScheme.primary
            : null,
        items: [
          destination(
            AppStrings.tabHome,
            'house',
            selectedSfSymbol: 'house.fill',
            HugeIcons.strokeRoundedHome01,
          ),
          destination(
            AppStrings.tabFits,
            'hand.thumbsup',
            selectedSfSymbol: 'hand.thumbsup.fill',
            HugeIcons.strokeRoundedThumbsUp,
          ),
          isRecruiter
              ? destination(
                  AppStrings.tabCareers,
                  'briefcase',
                  selectedSfSymbol: 'briefcase.fill',
                  HugeIcons.strokeRoundedBriefcase01,
                )
              : destination(
                  AppStrings.tabProgress,
                  'chart.bar',
                  selectedSfSymbol: 'chart.bar.fill',
                  HugeIcons.strokeRoundedAnalyticsUp,
                ),
          destination(
            AppStrings.tabSearch,
            'magnifyingglass',
            HugeIcons.strokeRoundedSearch01,
          ),
          destination(
            AppStrings.tabNotifications,
            'bell',
            selectedSfSymbol: 'bell.fill',
            HugeIcons.strokeRoundedNotification01,
          ),
        ],
      ),
    );
  }
}
