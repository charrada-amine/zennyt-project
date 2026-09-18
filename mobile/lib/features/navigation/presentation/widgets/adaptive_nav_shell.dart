import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/responsive.dart';
import '../viewmodel/nav_tab_provider.dart';
import 'app_bottom_nav.dart';
import 'app_side_nav.dart';

/// Adaptive navigation chrome for the signed-in app.
///
/// * Phone (< [Responsive.tabletBreakpoint]): the five destinations live in an
///   [IndexedStack] with the floating [AppBottomNav] — unchanged behaviour.
/// * Tablet/desktop: the bottom bar is replaced by the persistent [AppSideNav]
///   (rail on tablets, expanded sidebar on desktop widths), matching the
///   tablet maquettes. Tab state stays in [navTabProvider] so switching shell
///   keeps the selected destination.
class AdaptiveNavShell extends ConsumerWidget {
  const AdaptiveNavShell({super.key, required this.pages, this.initialTab});

  final List<Widget> pages;
  final int? initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = initialTab ?? ref.watch(navTabProvider);
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide =
            MediaQuery.sizeOf(context).width >= Responsive.tabletBreakpoint;

        final content = IndexedStack(index: tab, children: pages);

        if (!isWide) {
          return Scaffold(
            backgroundColor: colors.scaffoldBg,
            body: content,
            bottomNavigationBar: AppBottomNav(
              selectedTab: tab,
              onSelect: (index) =>
                  ref.read(navTabProvider.notifier).select(index),
            ),
          );
        }

        final expanded = MediaQuery.sizeOf(context).width >=
            Responsive.desktopBreakpoint;
        return Scaffold(
          backgroundColor: colors.scaffoldBg,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSideNav(expanded: expanded, initialTab: tab),
              VerticalDivider(width: 1, thickness: 1, color: colors.navBorder),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}
