import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

class FitsScreen extends StatelessWidget {
  const FitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      icon: Icons.thumb_up_alt_outlined,
      label: AppStrings.tabFits,
    );
  }
}
