import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Interrupteur de l'app : UISwitch natif (Liquid Glass sur iOS 26+),
/// CupertinoSwitch sur iOS plus ancien, Switch Material sur Android — piste
/// active à la couleur de succès de la marque.
class ZennytSwitch extends StatelessWidget {
  const ZennytSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: context.colors.success,
    );
  }
}
