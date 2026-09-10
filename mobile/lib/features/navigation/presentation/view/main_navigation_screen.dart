import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../fits/presentation/view/fits_screen.dart';
import '../../../home/presentation/view/home_screen.dart';
import '../../../notifications/presentation/view/notifications_screen.dart';
import '../../../progress/presentation/view/progress_screen.dart';
import '../../../search/presentation/view/search_screen.dart';
import '../../../../core/theme/theme.dart';
import '../viewmodel/nav_tab_provider.dart';
import '../widgets/app_bottom_nav.dart';

/// The main app navigation shown after authentication. Hosts the five
/// bottom-nav destinations in an [IndexedStack] (state is preserved across tab
/// switches) and renders the shared [AppBottomNav].
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

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(navTabProvider);
    final tab = _localTab ?? selectedTab;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: _TabTransition(
        index: tab,
        child: IndexedStack(
          index: tab,
          children: [
            TickerMode(enabled: tab == 0, child: const HomeScreen()),
            TickerMode(enabled: tab == 1, child: const FitsScreen()),
            TickerMode(enabled: tab == 2, child: const ProgressScreen()),
            TickerMode(enabled: tab == 3, child: const SearchScreen()),
            TickerMode(enabled: tab == 4, child: const NotificationsScreen()),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedTab: tab,
        onSelect: (index) {
          setState(() => _localTab = null);
          ref.read(navTabProvider.notifier).select(index);
        },
      ),
    );
  }
}

/// Animates the existing stack in place so tab switching preserves form/scroll state.
class _TabTransition extends StatefulWidget {
  const _TabTransition({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_TabTransition> createState() => _TabTransitionState();
}

class _TabTransitionState extends State<_TabTransition>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.navigation,
    value: 1,
  );
  double _direction = 1;

  @override
  void didUpdateWidget(covariant _TabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _direction = widget.index > oldWidget.index ? 1 : -1;
      if (AppMotion.reduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final value = AppMotion.reduced(context)
          ? 1.0
          : AppMotion.curve.transform(_controller.value);
      return Opacity(
        opacity: .65 + .35 * value,
        child: Transform.translate(
          offset: Offset(16 * _direction * (1 - value), 0),
          child: child,
        ),
      );
    },
  );
}
