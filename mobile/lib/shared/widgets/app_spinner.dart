import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Indicateur d'activité coloré : `CupertinoActivityIndicator` sur iOS (à la
/// taille de sa boîte), `CircularProgressIndicator` ailleurs.
///
/// `CircularProgressIndicator.adaptive` ne suffit pas quand une couleur est
/// imposée : sur iOS il prend la couleur des traits dans `backgroundColor`,
/// qui est la couleur de piste sur Android.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.color, this.strokeWidth});

  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return CircularProgressIndicator(color: color, strokeWidth: strokeWidth);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return CupertinoActivityIndicator(
          color: color,
          radius: side.isFinite ? side / 2 : 10,
        );
      },
    );
  }
}
