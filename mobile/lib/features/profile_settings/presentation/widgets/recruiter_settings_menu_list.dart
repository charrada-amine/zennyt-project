import 'package:flutter/material.dart';
import 'settings_menu_list.dart';

/// Recruiter variant of the shared profile settings menu.
class RecruiterSettingsMenuList extends StatelessWidget {
  const RecruiterSettingsMenuList({super.key});

  @override
  Widget build(BuildContext context) => const SettingsMenuList(recruiter: true);
}
