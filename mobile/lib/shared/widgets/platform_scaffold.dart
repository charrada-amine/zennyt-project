import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme/app_color_scheme.dart';

class PlatformScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const PlatformScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (AppConstants.isCupertino) {
      final navBar = appBar is ObstructingPreferredSizeWidget
          ? appBar as ObstructingPreferredSizeWidget
          : null;

      return CupertinoPageScaffold(
        navigationBar: navBar,
        backgroundColor: backgroundColor ?? colors.cardSurface,
        child: bottomNavigationBar == null
            ? body
            : Column(
                children: [
                  Expanded(child: body),
                  bottomNavigationBar!,
                ],
              ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor ?? colors.scaffoldBg,
    );
  }
}
