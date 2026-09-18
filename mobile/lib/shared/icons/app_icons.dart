import 'package:flutter/material.dart' show ActionIconThemeData;
import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

export 'package:hugeicons/hugeicons.dart' show HugeIcons;

/// Données d'une icône HugeIcons (structure SVG sérialisée).
///
/// Toute l'application passe par ce type plutôt que par `IconData` : les
/// icônes Material et Cupertino ne sont plus utilisées.
typedef AppIconData = List<List<dynamic>>;

/// Icône de l'application (HugeIcons, style « stroke rounded »).
///
/// Remplaçant direct de [Icon] : même paramètres positionnels, et la taille
/// comme la couleur retombent sur l'[IconTheme] courant — une [AppIcon] dans un
/// `IconButton`, une `ListTile` ou une `AppBar` prend donc la même apparence
/// qu'une [Icon] Material l'aurait prise.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
    this.filled = false,
    this.semanticLabel,
  });

  final AppIconData? icon;
  final double? size;
  final Color? color;

  /// Épaisseur du trait (1.5 par défaut dans HugeIcons).
  final double? strokeWidth;

  /// Remplit les formes fermées (étoile de note, pastille pleine…) : HugeIcons
  /// ne propose que des contours.
  final bool filled;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final iconSize = size ?? theme.size ?? 24;
    final data = icon;
    if (data == null) {
      return Semantics(
        label: semanticLabel,
        child: SizedBox(width: iconSize, height: iconSize),
      );
    }

    var iconColor = color ?? theme.color ?? const Color(0xFF000000);
    final opacity = theme.opacity;
    if (color == null && opacity != null && opacity != 1.0) {
      iconColor = iconColor.withValues(alpha: iconColor.a * opacity);
    }

    final glyph = HugeIcon(
      icon: filled ? AppIcons.filledOf(data) : data,
      size: iconSize,
      color: iconColor,
      strokeWidth: strokeWidth,
    );

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: Center(child: glyph),
        ),
      ),
    );
  }
}

/// Icônes propres à l'application, en plus du catalogue [HugeIcons].
abstract final class AppIcons {
  static final Expando<AppIconData> _filled = Expando('filled');

  /// Variante remplie d'une icône : chaque forme tracée reçoit aussi un
  /// remplissage à la couleur du trait. Mise en cache par icône.
  static AppIconData filledOf(AppIconData icon) => _filled[icon] ??= [
        for (final element in icon)
          [
            element[0],
            {
              ...(element[1] as Map<String, dynamic>),
              if ((element[1] as Map<String, dynamic>)['stroke'] ==
                  'currentColor')
                'fill': 'currentColor',
            },
          ],
      ];

  /// Pouce levé plein (« j'aime » actif).
  static final AppIconData thumbsUpFilled =
      filledOf(HugeIcons.strokeRoundedThumbsUp);

  /// Étoile pleine (notes, favoris) — utilisable en `const`.
  static const AppIconData starFilled = [
    [
      'path',
      {
        'd':
            'M13.7276 3.44418L15.4874 6.99288C15.7274 7.48687 16.3673 7.9607 16.9073 8.05143L20.0969 8.58575C22.1367 8.92853 22.6167 10.4206 21.1468 11.8925L18.6671 14.3927C18.2471 14.8161 18.0172 15.6327 18.1471 16.2175L18.8571 19.3125C19.417 21.7623 18.1271 22.71 15.9774 21.4296L12.9877 19.6452C12.4478 19.3226 11.5579 19.3226 11.0079 19.6452L8.01827 21.4296C5.8785 22.71 4.57865 21.7522 5.13859 19.3125L5.84851 16.2175C5.97849 15.6327 5.74852 14.8161 5.32856 14.3927L2.84884 11.8925C1.389 10.4206 1.85895 8.92853 3.89872 8.58575L7.08837 8.05143C7.61831 7.9607 8.25824 7.48687 8.49821 6.99288L10.258 3.44418C11.2179 1.51861 12.7777 1.51861 13.7276 3.44418Z',
        'stroke': 'currentColor',
        'fill': 'currentColor',
        'strokeWidth': '1.5',
        'strokeLinecap': 'round',
        'strokeLinejoin': 'round',
      },
    ],
  ];

  /// Pastille pleine (puces, indicateurs d'état) — utilisable en `const`.
  static const AppIconData circleFilled = [
    [
      'circle',
      {
        'cx': '12',
        'cy': '12',
        'r': '10',
        'stroke': 'currentColor',
        'fill': 'currentColor',
        'strokeWidth': '1.5',
      },
    ],
  ];
}

/// Icônes des boutons que Flutter dessine lui-même (`BackButton`, retour
/// implicite d'une `AppBar`, `CloseButton`, boutons de tiroir) : sans ce
/// thème, ils resteraient en glyphes Material.
final ActionIconThemeData appActionIconTheme = ActionIconThemeData(
  backButtonIconBuilder: (_) =>
      const AppIcon(HugeIcons.strokeRoundedArrowLeft01),
  closeButtonIconBuilder: (_) => const AppIcon(HugeIcons.strokeRoundedCancel01),
  drawerButtonIconBuilder: (_) => const AppIcon(HugeIcons.strokeRoundedMenu01),
  endDrawerButtonIconBuilder: (_) =>
      const AppIcon(HugeIcons.strokeRoundedMenu01),
);
