import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/shared/icons/app_icons.dart';

/// Équivalent de `find.byIcon` pour les [AppIcon] (HugeIcons).
Finder findAppIcon(AppIconData icon) => find.byWidgetPredicate(
      (widget) => widget is AppIcon && identical(widget.icon, icon),
      description: 'AppIcon($icon)',
    );

/// Équivalent de `find.widgetWithIcon` pour les [AppIcon].
Finder findWidgetWithAppIcon(Type widgetType, AppIconData icon) =>
    find.ancestor(of: findAppIcon(icon), matching: find.byType(widgetType));
