import 'package:flutter/material.dart';
import '../../features/navigation/presentation/widgets/app_bottom_nav.dart';

/// Platform bottom navigation widget, delegating to the unified [AppBottomNav].
class PlatformBottomNavigation extends StatelessWidget {
  const PlatformBottomNavigation({super.key, dynamic navigationShell});

  @override
  Widget build(BuildContext context) {
    return const AppBottomNav();
  }
}
