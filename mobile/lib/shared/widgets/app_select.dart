import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'app_popup_menu.dart';
import 'package:zennyt/shared/icons/app_icons.dart';

/// Sélecteur d'une valeur dans une liste courte.
///
/// iOS 26+ : champ qui ouvre un `UIMenu` natif Liquid Glass (coche sur la
/// valeur courante). Ailleurs : le menu déroulant Material [material] fourni
/// par l'écran, inchangé, pour garder le style de chaque formulaire.
///
/// Avec [decoration] ou [validator], le champ iOS est un [FormField] : il
/// s'affiche comme les autres champs et participe à la validation du [Form].
class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    required this.material,
    this.hint,
    this.style,
    this.chevronColor,
    this.decoration,
    this.validator,
  });

  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T?>? onChanged;
  final Widget material;
  final String? hint;
  final TextStyle? style;
  final Color? chevronColor;
  final InputDecoration? decoration;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    if (!PlatformInfo.isIOS26OrHigher()) return material;

    if (decoration == null && validator == null) {
      return _menu(
        context,
        onSelected: (option) => onChanged?.call(option),
        child: _row(context, value),
      );
    }

    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (field) => _menu(
        context,
        onSelected: (option) {
          field.didChange(option);
          onChanged?.call(option);
        },
        child: InputDecorator(
          decoration: (decoration ?? const InputDecoration()).copyWith(
            errorText: field.errorText,
          ),
          isEmpty: field.value == null,
          // L'InputDecorator affiche déjà l'indice quand la valeur est vide.
          child: _row(context, field.value, showHint: false),
        ),
      ),
    );
  }

  Widget _menu(
    BuildContext context, {
    required ValueChanged<T> onSelected,
    required Widget child,
  }) {
    return AppPopupMenu(
      entries: [
        for (final option in options)
          AppMenuAction(
            label: labelOf(option),
            sfSymbol: option == value ? 'checkmark' : null,
            enabled: onChanged != null,
            onSelected: () => onSelected(option),
          ),
      ],
      child: child,
    );
  }

  Widget _row(BuildContext context, T? current, {bool showHint = true}) {
    final colors = context.colors;
    final textStyle =
        style ?? AppTypography.bodyMedium.copyWith(color: colors.textPrimary);
    return Row(
      children: [
        Expanded(
          child: Text(
            current == null ? (showHint ? hint ?? '' : '') : labelOf(current),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: current == null
                ? textStyle.copyWith(color: colors.textMuted)
                : textStyle,
          ),
        ),
        AppIcon(
          HugeIcons.strokeRoundedArrowDown01,
          size: 20,
          color: chevronColor ?? colors.textSecondary,
        ),
      ],
    );
  }
}
