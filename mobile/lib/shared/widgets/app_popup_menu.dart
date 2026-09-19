import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'package:zennyt/shared/icons/app_icons.dart';

/// Une entrée de [AppPopupMenu] : une action ou un séparateur.
sealed class AppMenuEntry {
  const AppMenuEntry();
}

/// Action d'un [AppPopupMenu]. [sfSymbol] sert au menu natif iOS 26+,
/// [icon] au menu Material (Android, iOS < 26).
class AppMenuAction extends AppMenuEntry {
  const AppMenuAction({
    required this.label,
    this.subtitle,
    this.sfSymbol,
    this.icon,
    this.destructive = false,
    this.enabled = true,
    this.onSelected,
  });

  final String label;
  final String? subtitle;
  final String? sfSymbol;
  final AppIconData? icon;
  final bool destructive;
  final bool enabled;
  final VoidCallback? onSelected;
}

class AppMenuDivider extends AppMenuEntry {
  const AppMenuDivider();
}

/// Menu contextuel « ⋯ » de l'app : `UIMenu` natif Liquid Glass sur iOS 26+,
/// menu Material aux couleurs de la marque ailleurs.
class AppPopupMenu extends StatelessWidget {
  const AppPopupMenu({
    super.key,
    required this.entries,
    required this.child,
    this.tooltip,
  }) : icon = null,
       iconColor = null,
       iconSize = null;

  /// Déclencheur icône (bouton rond « ⋯ », « ⋮ »…).
  const AppPopupMenu.icon({
    super.key,
    required this.entries,
    required AppIconData this.icon,
    this.iconColor,
    this.iconSize,
    this.tooltip,
  }) : child = null;

  final List<AppMenuEntry> entries;
  final Widget? child;
  final String? tooltip;
  final AppIconData? icon;
  final Color? iconColor;
  final double? iconSize;

  List<AppMenuAction> get _actions =>
      entries.whereType<AppMenuAction>().toList();

  @override
  Widget build(BuildContext context) {
    final trigger =
        child ??
        Padding(
          padding: const EdgeInsets.all(8),
          child: AppIcon(icon!, color: iconColor, size: iconSize),
        );

    if (PlatformInfo.isIOS26OrHigher()) {
      final actions = _actions;
      return AdaptivePopupMenuButton.widget<int>(
        items: [
          for (final entry in entries)
            switch (entry) {
              AppMenuDivider() => const AdaptivePopupMenuDivider(),
              AppMenuAction() => AdaptivePopupMenuItem<int>(
                label: entry.label,
                subtitle: entry.subtitle,
                icon: entry.sfSymbol,
                enabled: entry.enabled,
                isDestructive: entry.destructive,
                value: actions.indexOf(entry),
              ),
            },
        ],
        onSelected: (_, item) => actions[item.value!].onSelected?.call(),
        child: trigger,
      );
    }

    return _MaterialMenu(
      entries: entries,
      tooltip: tooltip,
      icon: icon == null
          ? null
          : AppIcon(icon!, color: iconColor, size: iconSize),
      child: child,
    );
  }
}

class _MaterialMenu extends StatelessWidget {
  const _MaterialMenu({
    required this.entries,
    this.tooltip,
    this.icon,
    this.child,
  });

  final List<AppMenuEntry> entries;
  final String? tooltip;
  final Widget? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actions = entries.whereType<AppMenuAction>().toList();

    return PopupMenuButton<int>(
      tooltip: tooltip,
      icon: icon,
      color: colors.cardSurface,
      elevation: 6,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      onSelected: (index) => actions[index].onSelected?.call(),
      itemBuilder: (context) => [
        for (final entry in entries)
          switch (entry) {
            AppMenuDivider() => const PopupMenuDivider(),
            AppMenuAction() => PopupMenuItem<int>(
              value: actions.indexOf(entry),
              enabled: entry.enabled,
              child: _MenuRow(action: entry),
            ),
          },
      ],
      child: child,
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.action});

  final AppMenuAction action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = action.destructive ? colors.error : colors.textPrimary;
    final icon = action.icon;

    return Row(
      children: [
        if (icon != null) ...[
          AppIcon(
            icon,
            size: 18,
            color: action.destructive ? colors.error : colors.iconDefault,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight: action.subtitle != null ? FontWeight.w700 : null,
                ),
              ),
              if (action.subtitle != null)
                Text(
                  action.subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
