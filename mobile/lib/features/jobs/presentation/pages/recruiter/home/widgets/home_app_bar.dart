import 'package:flutter/material.dart';

import 'package:zennyt/shared/widgets/custom_app_bar.dart';
import 'package:zennyt/shared/widgets/session_avatar.dart';
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return const CustomAppBar(
      title: 'Careers',
      trailingAction: SessionAvatar(),
    );
  }
}
